import Foundation
import EventKit

class CalendarViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published var currentMonth = Calendar.current.component(.month, from: Date())
    @Published var currentYear = Calendar.current.component(.year, from: Date())
    @Published var events: [EventModel] = []

    private let calendarService = CalendarSyncService()

    enum DisplayMode {
        case monthly, yearly
    }

    func moveToPrevoiusMonth() {
        if currentMonth == 1 {
            currentMonth = 12
            currentYear -= 1
        } else {
            currentMonth -= 1
        }
        loadEventsForCurrentMonth()
    }

    func moveToNextMonth() {
        if currentMonth == 12 {
            currentMonth = 1
            currentYear += 1
        } else {
            currentMonth += 1
        }
        loadEventsForCurrentMonth()
    }

    func loadEventsForCurrentMonth() {
        var components = DateComponents()
        components.year = currentYear
        components.month = currentMonth
        components.day = 1
        guard let startDate = Calendar.current.date(from: components) else { return }
        guard let endDate = Calendar.current.date(
            byAdding: DateComponents(month: 1, day: -1),
            to: startDate
        ) else {
            return
        }
        let fetchedEvents = calendarService.fetchEventsModel(startDate: startDate, endDate: endDate)
        self.events = fetchedEvents
    }

    /// Получить события за весь год (для YearlyView)
    func getEventsForYear(year: Int) -> [Date: [EventModel]] {
        var components = DateComponents()
        components.year = year
        components.month = 1
        components.day = 1
        guard let startDate = Calendar.current.date(from: components) else { return [:] }
        guard let endDate = Calendar.current.date(byAdding: DateComponents(year: 1, day: -1), to: startDate) else { return [:] }
        let yearEvents = calendarService.fetchEventsModel(startDate: startDate, endDate: endDate)
        var dict = [Date: [EventModel]]()
        let calendar = Calendar.current
        for event in yearEvents {
            let day = calendar.startOfDay(for: event.startDate)
            dict[day, default: []].append(event)
        }
        return dict
    }

    func initialize() {
        loadEventsForCurrentMonth()
    }
}
