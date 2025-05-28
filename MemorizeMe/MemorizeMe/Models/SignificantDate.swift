import Foundation
import SwiftData
import EventKit

/// Тип, представляющий различные категории значимых дат
enum SignificantDateType: String, Codable, CaseIterable {
    /// Годовщина события
    case anniversary
    /// Особая красивая дата (например, 11.11 или 22.02)
    case prettyDate
    /// Действие, которое нужно выполнить
    case action
    /// Поздравление
    case greeting
    /// Воспоминание о прошлом событии
    case throwback
    /// Другое
    case other
    
    /// Вычисляемое свойство для получения текстового описания типа
    var description: String {
        switch self {
        case .anniversary:
            return "Годовщина"
        case .prettyDate:
            return "Красивая дата"
        case .action:
            return "Действие"
        case .greeting:
            return "Поздравление"
        case .throwback:
            return "Воспоминание"
        case .other:
            return "Другое"
        }
    }
    
    /// Цвет для выделения в календаре
    var calendarColor: String {
        switch self {
        case .greeting: return "primaryLight6"
        case .other: return "lightOrange"
        case .prettyDate: return "lightPurple"
        case .throwback: return "lightBlue"
        case .action: return "lightRed"
        case .anniversary: return "lightGreen"
        }
    }
}

/// Расширение с функциями склонения слов "год" и "день" по правилам русского языка
extension SignificantDateType {
    /// Статическая функция для правильного склонения слова "год"
    static func pluralYears(_ count: Int) -> String {
        let lastDigit = count % 10
        let lastTwoDigits = count % 100
        
        // Обработка исключений для чисел от 11 до 14
        if lastTwoDigits >= 11 && lastTwoDigits <= 14 {
            return "лет"
        }
        
        // Обработка остальных случаев по последней цифре
        switch lastDigit {
        case 1: return "год"
        case 2, 3, 4: return "года"
        default: return "лет"
        }
    }
    
    /// Статическая функция для правильного склонения слова "день"
    static func pluralDays(_ count: Int) -> String {
        let lastDigit = count % 10
        let lastTwoDigits = count % 100
        
        // Обработка исключений для чисел от 11 до 14
        if lastTwoDigits >= 11 && lastTwoDigits <= 14 {
            return "дней"
        }
        
        // Обработка остальных случаев по последней цифре
        switch lastDigit {
        case 1: return "день"
        case 2, 3, 4: return "дня"
        default: return "дней"
        }
    }
}

/// Модель значимой даты, связанная с событием календаря
@Model
final class SignificantDate {
    @Attribute(.unique) var id: UUID = UUID()
    
    /// ID события из календаря
    var eventID: String
    /// Название события
    var eventTitle: String
    /// Дата начала события
    var eventStartDate: Date
    /// Заметки события
    var eventNotes: String?
    
    /// Тип значимой даты
    var type: SignificantDateType
    /// Дополнительные данные (например, количество лет для anniversary)
    var typeData: Int?
    /// Дата, когда необходимо отправить уведомление
    var notificationDate: Date
    /// Было ли уже отправлено уведомление
    var isNotified: Bool = false
    
    init(relatedEvent: EventModel, type: SignificantDateType, typeData: Int? = nil, notificationDate: Date) {
        self.eventID = relatedEvent.id
        self.eventTitle = relatedEvent.title
        self.eventStartDate = relatedEvent.startDate
        self.eventNotes = relatedEvent.notes
        self.type = type
        self.typeData = typeData
        self.notificationDate = notificationDate
    }
    
    /// Заголовок уведомления, сформированный на основе типа даты и события
    var title: String {
        switch type {
        case .anniversary:
            let years = typeData ?? 1
            return "\(years) \(SignificantDateType.pluralYears(years)) с момента \"\(eventTitle)\""
        case .prettyDate:
            return "Сегодня красивая дата для события \"\(eventTitle)\""
        case .action:
            return "Напоминание: \(eventTitle)"
        case .greeting:
            return "Не забудьте поздравить: \(eventTitle)"
        case .throwback:
            return "Воспоминание: \(eventTitle)"
        case .other:
            return "Событие: \(eventTitle)"
        }
    }
    
    /// Создает EventModel из сохраненных данных
    var relatedEvent: EventModel {
        return EventModel(
            id: eventID,
            title: eventTitle,
            startDate: eventStartDate,
            endDate: eventStartDate,
            notes: eventNotes
        )
    }
}

// Добавим extension для EventModel чтобы он работал без EKEvent
extension EventModel {
    init(id: String, title: String, startDate: Date, endDate: Date, notes: String?) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
        self.isAllDay = false
        // Создаем фиктивный EKEvent для совместимости
        self.originalEKEvent = EKEvent(eventStore: EKEventStore())
    }
}
