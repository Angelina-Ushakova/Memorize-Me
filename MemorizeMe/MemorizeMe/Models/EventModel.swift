import Foundation
import EventKit

/// Модель, представляющая событие из календаря iOS
struct EventModel: Identifiable {
    /// Уникальный идентификатор событыия
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
    /// Ссылка на оригинальное событие из календаря iOS
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
