import Foundation
import SwiftData

final class DateAnalysisService {
    private let calendarService = CalendarSyncService()
    
    func refreshSpecialDates(modelContext: ModelContext) async {
        print("Начинаем анализ значимых дат...")
        
        let today = Calendar.current.startOfDay(for: Date())
        guard let windowStart = Calendar.current.date(byAdding: .day, value: -365, to: today),
              let windowEnd = Calendar.current.date(byAdding: .day, value: 365, to: today) else {
            print("Ошибка создания временного окна")
            return
        }
        
        let window = DateInterval(start: windowStart, end: windowEnd)
        let events = calendarService.fetchEventsModel(startDate: window.start, endDate: window.end)
        print("Загружено событий: \(events.count)")
        
        if events.isEmpty {
            print("Нет событий для анализа")
            return
        }
        
        let ranked = EventRanker.topSpecials(from: events, window: window, maxCount: 20)
        let specials = ReminderPlanner.build(ranked)
        
        await saveSpecialDates(specials, modelContext: modelContext)
        
        let notificationService = NotificationService()
        await notificationService.scheduleNotifications(for: specials)
        
        print("Анализ завершен успешно")
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
    
    private func saveSpecialDates(_ specials: [SignificantDate], modelContext: ModelContext) async {
        do {
            try modelContext.delete(model: SignificantDate.self)
            
            for special in specials {
                modelContext.insert(special)
            }
            
            try modelContext.save()
            print("Сохранено \(specials.count) значимых дат")
        } catch {
            print("Ошибка сохранения значимых дат: \(error)")
        }
    }
}
