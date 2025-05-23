import Foundation

/// Тип, представляющий различные категории значимых дат
enum SignificantDateType {
    /// Годовщина события. Хранит количество лет
    case anniversary(years: Int)
    /// Обратный отсчёт до события. Хранит количество дней
    case countdown(days: Int)
    /// Особая красивая дата (например, 11.11 или 22.02)
    case prettyDate
    
    /// Вычисляемое свойство для получения текстового описания типа
    var description: String {
        switch self {
        case .anniversary(let years):
            return "\(years) \(SignificantDateType.pluralYears(years))"
        case .countdown(let days):
            return "Осталось \(days) \(SignificantDateType.pluralDays(days))"
        case .prettyDate:
            return "Красивая дата"
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
struct SignificantDate: Identifiable {
    /// Уникальный идентификатор даты
    var id: UUID = UUID()
    /// Событие, к которому привязана значимая дата
    var relatedEvent: EventModel
    /// Тип значимой даты (годовщина, отсчёт, красивая дата)
    var type: SignificantDateType
    /// Дата, когда необходимо отправить уведомление
    var notificationDate: Date
    /// Было ли уже отправлено уведомление (по умолчанию false)
    var isNotified: Bool = false
    
    /// Заголовок уведомления, сформированный на основе типа даты и события
    var title: String {
        switch type {
        case .anniversary(let years):
            return "\(years) \(SignificantDateType.pluralYears(years)) с момента \"\(relatedEvent.title)\""
        case .countdown(let days):
            return "До \"\(relatedEvent.title)\" осталось \(days) \(SignificantDateType.pluralDays(days))"
        case .prettyDate:
            return "Сегодня красивая дата для события \"\(relatedEvent.title)\""
        }
    }
}
