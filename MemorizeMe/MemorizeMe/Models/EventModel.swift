import Foundation
import EventKit

/// Модель, представляющая событие из календаря iOS
struct EventModel: Identifiable {
    /// Уникальный идентификатор события
    var id: String
    /// Название события
    var title: String
    /// Дата и время начала события
    var startDate: Date
    /// Дата и время окончания события
    var endDate: Date
    /// Дополнительные заметки к событию (опциональные)
    var notes: String?
    /// Флаг, указывающий, идёт ли событие целый день
    var isAllDay: Bool
    /// Правила повторения события (nil для неповторяющихся событий)
    var recurrenceRules: [EKRecurrenceRule]?
    /// Ссылка на оригинальное событие из календаря iOS
    var originalEKEvent: EKEvent

    // Инициализатор из EKEvent
    init(from ekEvent: EKEvent) {
        self.id = ekEvent.eventIdentifier
        self.title = ekEvent.title
        self.startDate = ekEvent.startDate
        self.endDate = ekEvent.endDate
        self.notes = ekEvent.notes
        self.isAllDay = ekEvent.isAllDay
        self.recurrenceRules = ekEvent.recurrenceRules
        self.originalEKEvent = ekEvent
    }

    /// Custom инициализатор для совместимости с тестами или "старым" кодом
    init(id: String, title: String, startDate: Date, endDate: Date, notes: String? = nil, isAllDay: Bool = false, recurrenceRules: [EKRecurrenceRule]? = nil) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
        self.isAllDay = isAllDay
        self.recurrenceRules = recurrenceRules
        // Создаем фиктивный EKEvent для совместимости
        self.originalEKEvent = EKEvent(eventStore: EKEventStore())
    }

    /// Проверяет, является ли событие повторяющимся
    var isRecurring: Bool {
        return recurrenceRules != nil && !(recurrenceRules?.isEmpty ?? true)
    }
}
