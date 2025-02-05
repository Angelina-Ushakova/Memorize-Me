import EventKit

final class CalendarSyncService {
    private let eventStore = EKEventStore()
    
    /// Запрашивает у пользователя разрешение на доступ к календарю
    func requestAccess(completion: @escaping (Bool) -> Void) {
        eventStore.requestAccess(to: .event) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    /// Получает события из календаря пользователя
    func fetchEvents(startDate: Date, endDate: Date) -> [EKEvent] {
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)
        return events
    }
    
    /// Проверяет текущий статус доступа к календарю
    func getAuthorizationStatus() async -> Bool? {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized:
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
