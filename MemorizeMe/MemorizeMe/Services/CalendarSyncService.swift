import Foundation
import EventKit

/// Сервис для работы с календарём: проверка доступа и загрузка событий
final class CalendarSyncService {
    /// Хранилище событий календаря
    private let eventStore = EKEventStore()
    
    // MARK: - Public Methods
    
    /// Запрашивает у пользователя разрешение на доступ к календарю
    /// - Parameter completion: колбэк с результатом - `true`, если доступ разрешён
    func requestAccess(completion: @escaping (Bool) -> Void) {
            eventStore.requestFullAccessToEvents { granted, _ in
                DispatchQueue.main.async { completion(granted) }
            }
        }
    
    /// Возвращает список событий за указанный период
    /// - Parameters:
    ///   - startDate: начальная граница периода
    ///   - endDate: конечная граница периода
    /// - Returns: массив объектов `EKEvent`
    func fetchEvents(startDate: Date, endDate: Date) -> [EKEvent] {
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)
        return events
    }
    
    /// Преобразует события в модели `EventModel`
    /// - Parameters:
    ///   - startDate: начало диапазона
    ///   - endDate: конец диапазона
    /// - Returns: массив моделей `EventModel`
    func fetchEventsModel(startDate: Date, endDate: Date) -> [EventModel] {
        let events = fetchEvents(startDate: startDate, endDate: endDate)
        return events.map {EventModel(from: $0)}
    }
    
    /// Проверяет текущий статус доступа к календарю
    /// - Returns: Optional Bool: true если доступ разрешен, false если запрещен, nil если не определен
    func getAuthorizationStatus() async -> Bool? {
        // Получаем текущий статус авторизации для доступа к событиям календаря
        let status = EKEventStore.authorizationStatus(for: .event)
        // Возвращаем соответствующее значение в зависимости от статуса
        switch status {
        case .authorized, .fullAccess, .writeOnly:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            return nil
        @unknown default:
            return false
        }
    }
}
