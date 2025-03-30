import Foundation
import EventKit

struct EventModel: Identifiable {
    var id: String
    var title: String
    var startDate: Date
    var endDate: Date
    var notes: String?
    var isAllDay: Bool
    var originalEKEvent: EKEvent
    
    init(from ekEvent: EKEvent) {
        self.id = ekEvent.eventIdentifier
        self.title = ekEvent.title
        self.startDate = ekEvent.startDate
        self.endDate = ekEvent.endDate
        self.notes = ekEvent.notes
        self.isAllDay = ekEvent.isAllDay
        self.originalEKEvent = ekEvent
    }
}

// Перечисление для типов значимых дат
enum SignificantDateType {
    case anniversary(years: Int)   // Годовщина (сколько лет прошло)
    case countdown(days: Int)      // Отсчет (сколько дней осталось)
    case prettyDate                // Красивая дата (например, 11.11)
    
    var description: String {
        switch self {
        case .anniversary(let years):
            return "\(years) \(pluralYears(years))"
        case .countdown(let days):
            return "Осталось \(days) \(pluralDays(days))"
        case .prettyDate:
            return "Красивая дата"
        }
    }
    
    // Функция для правильного склонения слова "год"
    private func pluralYears(_ count: Int) -> String {
        let lastDigit = count % 10
        let lastTwoDigits = count % 100
        
        if lastTwoDigits >= 11 && lastTwoDigits <= 19 {
            return "лет"
        }
        
        switch lastDigit {
        case 1: return "год"
        case 2, 3, 4: return "года"
        default: return "лет"
        }
    }
    
    // Функция для правильного склонения слова "день"
    private func pluralDays(_ count: Int) -> String {
        let lastDigit = count % 10
        let lastTwoDigits = count % 100
        
        if lastTwoDigits >= 11 && lastTwoDigits <= 19 {
            return "дней"
        }
        
        switch lastDigit {
        case 1: return "день"
        case 2, 3, 4: return "дня"
        default: return "дней"
        }
    }
}

// Структура для значимой даты
struct SignificantDate: Identifiable {
    var id: UUID = UUID()
    var relatedEvent: EventModel
    var type: SignificantDateType
    var notificationDate: Date
    var isNotified: Bool = false
    
    var title: String {
        switch type {
        case .anniversary(let years):
            return "\(years) \(years == 1 ? "год" : "лет") с момента \"\(relatedEvent.title)\""
        case .countdown(let days):
            return "До \"\(relatedEvent.title)\" осталось \(days) \(days == 1 ? "день" : "дней")"
        case .prettyDate:
            return "Сегодня красивая дата для события \"\(relatedEvent.title)\""
        }
    }
}
