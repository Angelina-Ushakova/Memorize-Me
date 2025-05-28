import Foundation
import SwiftData
import SwiftUI

@MainActor
final class SignificantDateViewModel: ObservableObject {
    @Published var specialDates: [SignificantDate] = []
    @Published var isAnalyzing = false
    @Published var lastAnalysisDate: Date?
    @Published var analysisError: String?
    @Published var pendingNotificationsCount = 0
    
    private let dateAnalysisService = DateAnalysisService()
    private let notificationService = NotificationService()
    
    func initialize(modelContext: ModelContext) async {
        await loadSpecialDates(modelContext: modelContext)
        await updateNotificationCount()
        
        let status = await notificationService.checkPermissionStatus()
        if status == .notDetermined {
            _ = await notificationService.requestPermission()
        }
        
        // При инициализации делаем инкрементальное обновление только если давно не обновлялись
        if shouldRefreshAnalysis() {
            await incrementalRefreshAnalysis(modelContext: modelContext)
        }
    }
    
    /// Полное обновление анализа - для ручного запуска через настройки
    func fullRefreshAnalysis(modelContext: ModelContext) async {
        isAnalyzing = true
        analysisError = nil

        await dateAnalysisService.fullRefreshSpecialDates(modelContext: modelContext)
        await loadSpecialDates(modelContext: modelContext)
        await updateNotificationCount()
        lastAnalysisDate = Date()

        isAnalyzing = false
    }
    
    /// Инкрементальное обновление - для автоматических обновлений
    func incrementalRefreshAnalysis(modelContext: ModelContext) async {
        guard !isAnalyzing else { return }
        
        isAnalyzing = true
        analysisError = nil
        
        await dateAnalysisService.incrementalRefreshSpecialDates(modelContext: modelContext)
        await loadSpecialDates(modelContext: modelContext)
        await updateNotificationCount()
        lastAnalysisDate = Date()
        
        isAnalyzing = false
    }
    
    /// Для обратной совместимости - по умолчанию инкрементальное обновление
    func refreshAnalysis(modelContext: ModelContext) async {
        await incrementalRefreshAnalysis(modelContext: modelContext)
    }
    
    func loadSpecialDates(modelContext: ModelContext) async {
        specialDates = dateAnalysisService.getSpecialDates(modelContext: modelContext)
        updateWidgetData()
    }
    
    func deleteSpecialDate(_ specialDate: SignificantDate, modelContext: ModelContext) async {
        await dateAnalysisService.deleteSpecialDate(specialDate, modelContext: modelContext)
        await loadSpecialDates(modelContext: modelContext)
        await updateNotificationCount()
    }
    
    func getSpecialDatesForMonth(year: Int, month: Int, modelContext: ModelContext) -> [Date: [SignificantDate]] {
        return dateAnalysisService.getSpecialDatesForMonth(year: year, month: month, modelContext: modelContext)
    }
    
    func getUpcomingDates(limit: Int = 5) -> [SignificantDate] {
        let now = Date()
        return specialDates
            .filter { $0.notificationDate >= now }
            .sorted { $0.notificationDate < $1.notificationDate }
            .prefix(limit)
            .map { $0 }
    }
    
    func shouldRefreshAnalysis() -> Bool {
        guard let lastDate = lastAnalysisDate else { return true }
        let hoursSinceLastAnalysis = Date().timeIntervalSince(lastDate) / 3600
        return hoursSinceLastAnalysis > 24
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        
        if Calendar.current.isDate(date, inSameDayAs: Date()) {
            return "Сегодня"
        } else if Calendar.current.isDate(date, inSameDayAs: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()) {
            return "Завтра"
        } else if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date).capitalized
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    private func updateNotificationCount() async {
        pendingNotificationsCount = await notificationService.getPendingNotificationsCount()
    }
    
    func updateWidgetData() {
        let appGroupID = "group.edu.hse.Ushakova.MemorizeMe"
        let userDefaults = UserDefaults(suiteName: appGroupID)
        let upcoming = getUpcomingDates(limit: 3)
        
        for (idx, item) in upcoming.enumerated() {
            userDefaults?.set(item.eventTitle, forKey: "widgetTitle\(idx)")
            userDefaults?.set(item.notificationDate.timeIntervalSince1970, forKey: "widgetDate\(idx)")
            userDefaults?.set(item.type.description, forKey: "widgetType\(idx)")
        }
        
        // Очищаем неиспользуемые слоты
        for idx in upcoming.count..<3 {
            userDefaults?.removeObject(forKey: "widgetTitle\(idx)")
            userDefaults?.removeObject(forKey: "widgetType\(idx)")
            userDefaults?.removeObject(forKey: "widgetDate\(idx)")
        }
        
        if upcoming.isEmpty {
            userDefaults?.set("Нет напоминаний", forKey: "widgetTitle0")
            userDefaults?.set("Другое", forKey: "widgetType0")
            userDefaults?.set(Date().timeIntervalSince1970, forKey: "widgetDate0")
        }
        
        userDefaults?.synchronize()
    }
}
