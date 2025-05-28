import Foundation
import SwiftData

final class DateAnalysisService {
    private let calendarService = CalendarSyncService()
    
    // MARK: - Public Methods
    
    /// Полное обновление - очищает все существующие напоминания и создает новые
    func fullRefreshSpecialDates(modelContext: ModelContext) async {
        print("Начинаем полный анализ значимых дат...")
        await performAnalysis(modelContext: modelContext, isIncremental: false)
    }
    
    /// Инкрементальное обновление - добавляет новые напоминания к существующим
    func incrementalRefreshSpecialDates(modelContext: ModelContext) async {
        print("Начинаем инкрементальное обновление значимых дат...")
        await performAnalysis(modelContext: modelContext, isIncremental: true)
    }
    
    // Для обратной совместимости - по умолчанию инкрементальное обновление
    func refreshSpecialDates(modelContext: ModelContext) async {
        await incrementalRefreshSpecialDates(modelContext: modelContext)
    }
    
    func getSpecialDates(modelContext: ModelContext) -> [SignificantDate] {
        do {
            let descriptor = FetchDescriptor<SignificantDate>(
                sortBy: [SortDescriptor(\.notificationDate)]
            )
            return try modelContext.fetch(descriptor)
        } catch {
            print("Ошибка загрузки значимых дат: \(error)")
            return []
        }
    }
    
    func getSpecialDatesForMonth(year: Int, month: Int, modelContext: ModelContext) -> [Date: [SignificantDate]] {
        let specials = getSpecialDates(modelContext: modelContext)
        var result: [Date: [SignificantDate]] = [:]
        
        for special in specials {
            let components = Calendar.current.dateComponents([.year, .month], from: special.notificationDate)
            if components.year == year && components.month == month {
                let day = Calendar.current.startOfDay(for: special.notificationDate)
                result[day, default: []].append(special)
            }
        }
        
        return result
    }
    
    func deleteSpecialDate(_ significantDate: SignificantDate, modelContext: ModelContext) async {
        modelContext.delete(significantDate)
        
        do {
            try modelContext.save()
            
            let notificationService = NotificationService()
            await notificationService.cancelNotification(id: significantDate.id.uuidString)
            
            print("Удалена значимая дата: \(significantDate.eventTitle)")
        } catch {
            print("Ошибка удаления значимой даты: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func performAnalysis(modelContext: ModelContext, isIncremental: Bool) async {
        let today = Calendar.current.startOfDay(for: Date())
        guard let windowStart = Calendar.current.date(byAdding: .day, value: -365, to: today),
              let windowEnd = Calendar.current.date(byAdding: .day, value: 365, to: today) else {
            print("Ошибка создания временного окна")
            return
        }
        
        // Основной проход: ±1 год для всех типов кроме годовщин
        let mainWindow = DateInterval(start: windowStart, end: windowEnd)
        let mainEvents = calendarService.fetchEventsModel(startDate: mainWindow.start, endDate: mainWindow.end)
        print("Загружено событий (основной проход): \(mainEvents.count)")
        
        // Дополнительный проход: только для годовщин (10 лет назад до вчера)
        guard let anniversaryStart = Calendar.current.date(byAdding: .year, value: -10, to: today),
              let anniversaryEnd = Calendar.current.date(byAdding: .day, value: -1, to: today) else {
            print("Ошибка создания окна для годовщин")
            return
        }
        
        let anniversaryWindow = DateInterval(start: anniversaryStart, end: anniversaryEnd)
        let anniversaryEvents = calendarService.fetchEventsModel(startDate: anniversaryWindow.start, endDate: anniversaryWindow.end)
            .filter { !$0.isRecurring } // Только нерекуррентные события
        print("Загружено событий для годовщин: \(anniversaryEvents.count)")
        
        if mainEvents.isEmpty && anniversaryEvents.isEmpty {
            print("Нет событий для анализа")
            return
        }
        
        // Анализируем оба набора событий
        let mainRanked = EventRanker.topSpecials(
            from: mainEvents,
            window: mainWindow,
            maxCount: 15,
            isFullAnalysis: !isIncremental,
            includeAnniversaries: false
        )
        
        let anniversaryRanked = EventRanker.topSpecials(
            from: anniversaryEvents,
            window: anniversaryWindow,
            maxCount: 5,
            isFullAnalysis: !isIncremental,
            includeAnniversaries: true
        )
        
        // Объединяем результаты и ограничиваем до 20
        let allRanked = (mainRanked + anniversaryRanked)
            .sorted { $0.score > $1.score }
            .prefix(20)
            .map { $0 }
        
        let newSpecials = ReminderPlanner.build(Array(allRanked))
        
        if isIncremental {
            await saveSpecialDatesIncremental(newSpecials, modelContext: modelContext)
        } else {
            await saveSpecialDatesFull(newSpecials, modelContext: modelContext)
        }
        
        // Обновляем уведомления
        let notificationService = NotificationService()
        let allSpecials = getSpecialDates(modelContext: modelContext)
        await notificationService.scheduleNotifications(for: allSpecials)
        
        print("Анализ завершен успешно")
    }
    
    /// Полное сохранение - удаляет все существующие и создает новые
    private func saveSpecialDatesFull(_ specials: [SignificantDate], modelContext: ModelContext) async {
        do {
            try modelContext.delete(model: SignificantDate.self)
            
            for special in specials {
                modelContext.insert(special)
            }
            
            try modelContext.save()
            print("Полное обновление: сохранено \(specials.count) значимых дат")
        } catch {
            print("Ошибка полного сохранения значимых дат: \(error)")
        }
    }
    
    /// Инкрементальное сохранение - добавляет только новые, удаляет устаревшие
    private func saveSpecialDatesIncremental(_ newSpecials: [SignificantDate], modelContext: ModelContext) async {
        do {
            let existingSpecials = getSpecialDates(modelContext: modelContext)
            let today = Date()
            
            // 1. Удаляем устаревшие напоминания (которые уже прошли)
            let expiredSpecials = existingSpecials.filter { $0.notificationDate < today }
            for expired in expiredSpecials {
                modelContext.delete(expired)
                print("Удалено устаревшее напоминание: \(expired.eventTitle)")
            }
            
            // 2. Получаем список существующих событий (не истекших)
            let existingEventIDs = Set(existingSpecials
                .filter { $0.notificationDate >= today }
                .map { $0.eventID })
            
            // 3. Добавляем только новые события
            var addedCount = 0
            for newSpecial in newSpecials {
                // Проверяем, нет ли уже такого события
                if !existingEventIDs.contains(newSpecial.eventID) {
                    modelContext.insert(newSpecial)
                    addedCount += 1
                    print("Добавлено новое напоминание: \(newSpecial.eventTitle)")
                }
            }
            
            try modelContext.save()
            print("Инкрементальное обновление: добавлено \(addedCount) новых дат, удалено \(expiredSpecials.count) устаревших")
        } catch {
            print("Ошибка инкрементального сохранения значимых дат: \(error)")
        }
    }
}
