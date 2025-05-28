import Foundation
import EventKit
import SwiftData

class CalendarViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published var currentMonth = Calendar.current.component(.month, from: Date())
    @Published var currentYear = Calendar.current.component(.year, from: Date())
    @Published var events: [EventModel] = []
    @Published var specialDatesForMonth: [Date: [SignificantDate]] = [:]

    private let calendarService = CalendarSyncService()
    private let dateAnalysisService = DateAnalysisService()

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
    
    func loadSpecialDatesForCurrentMonth(modelContext: ModelContext) {
        specialDatesForMonth = dateAnalysisService.getSpecialDatesForMonth(
            year: currentYear,
            month: currentMonth,
            modelContext: modelContext
        )
    }

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
    
    func getSpecialDatesForYear(year: Int, modelContext: ModelContext) -> [Date: [SignificantDate]] {
        var result: [Date: [SignificantDate]] = [:]
        
        for month in 1...12 {
            let monthSpecials = dateAnalysisService.getSpecialDatesForMonth(
                year: year,
                month: month,
                modelContext: modelContext
            )
            result.merge(monthSpecials) { existing, new in
                existing + new
            }
        }
        
        return result
    }
    
    func hasSpecialDates(for date: Date) -> Bool {
        let dayKey = Calendar.current.startOfDay(for: date)
        return specialDatesForMonth[dayKey] != nil && !specialDatesForMonth[dayKey]!.isEmpty
    }
    
    func getSpecialDates(for date: Date) -> [SignificantDate] {
        let dayKey = Calendar.current.startOfDay(for: date)
        return specialDatesForMonth[dayKey] ?? []
    }

    func initialize() {
        loadEventsForCurrentMonth()
    }
    
    func initialize(modelContext: ModelContext) {
        loadEventsForCurrentMonth()
        loadSpecialDatesForCurrentMonth(modelContext: modelContext)
    }
}
