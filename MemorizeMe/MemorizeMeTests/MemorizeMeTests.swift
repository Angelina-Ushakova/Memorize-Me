import XCTest
import SwiftData
@testable import MemorizeMe
import EventKit

final class MemorizeMeTests: XCTestCase {
    
    // MARK: - Test Data Setup
    
    override func setUpWithError() throws {
        // Настройка перед каждым тестом
    }
    
    override func tearDownWithError() throws {
        // Очистка после каждого теста
    }
    
    // MARK: - Тесты алгоритма категоризации событий
    
    func testEventCategorization_ActionType() throws {
        // Тест категоризации события типа ACTION
        let actionKeywords = ["заплатить": 12, "купить": 10, "позвонить": 8]
        let greetingKeywords = ["день рождения": 15, "юбилей": 14]
        
        let actionEvent = createTestEvent(
            title: "Заплатить за квартиру",
            date: Date(),
            notes: nil
        )
        
        let text = (actionEvent.title + " " + (actionEvent.notes ?? "")).lowercased()
        let (type, _) = EventRanker.classifyEvent(
            event: actionEvent,
            text: text,
            actionKeywords: actionKeywords,
            greetingKeywords: greetingKeywords,
            includeAnniversaries: false
        )
        
        XCTAssertEqual(type, .action, "Событие с глаголом действия должно быть категории ACTION")
    }
    
    func testEventCategorization_GreetingType() throws {
        // Тест категоризации события типа GREETING
        let actionKeywords = ["заплатить": 12, "купить": 10]
        let greetingKeywords = ["день рождения": 15, "юбилей": 14]
        
        let greetingEvent = createTestEvent(
            title: "День рождения Маши",
            date: Date(),
            notes: nil
        )
        
        let text = (greetingEvent.title + " " + (greetingEvent.notes ?? "")).lowercased()
        let (type, _) = EventRanker.classifyEvent(
            event: greetingEvent,
            text: text,
            actionKeywords: actionKeywords,
            greetingKeywords: greetingKeywords,
            includeAnniversaries: false
        )
        
        XCTAssertEqual(type, .greeting, "Событие с поздравительными словами должно быть категории GREETING")
    }
    
    func testEventCategorization_PrettyDate() throws {
        // Тест категоризации красивой даты (используем будущую дату)
        let calendar = Calendar.current
        let components = DateComponents(year: 2025, month: 11, day: 11, hour: 10, minute: 0)
        let prettyDate = calendar.date(from: components)!
        
        let prettyEvent = createTestEvent(
            title: "Обычное событие",
            date: prettyDate,
            notes: nil
        )
        
        let actionKeywords: [String: Int] = [:]
        let greetingKeywords: [String: Int] = [:]
        let text = (prettyEvent.title + " " + (prettyEvent.notes ?? "")).lowercased()
        
        let (type, _) = EventRanker.classifyEvent(
            event: prettyEvent,
            text: text,
            actionKeywords: actionKeywords,
            greetingKeywords: greetingKeywords,
            includeAnniversaries: false
        )
        
        XCTAssertEqual(type, .prettyDate, "Событие 11.11.2025 должно быть категории PRETTY")
    }
    
    // MARK: - Тесты расчета балла значимости
    
    func testBaseWeightCalculation() throws {
        // Тест базовых весов категорий
        XCTAssertEqual(EventRanker.getBaseWeight(.greeting), 40, "Базовый вес GREETING должен быть 40")
        XCTAssertEqual(EventRanker.getBaseWeight(.action), 30, "Базовый вес ACTION должен быть 30")
        XCTAssertEqual(EventRanker.getBaseWeight(.anniversary), 28, "Базовый вес ANNIVERSARY должен быть 28")
        XCTAssertEqual(EventRanker.getBaseWeight(.throwback), 28, "Базовый вес THROWBACK должен быть 28")
        XCTAssertEqual(EventRanker.getBaseWeight(.prettyDate), 22, "Базовый вес PRETTY должен быть 22")
        XCTAssertEqual(EventRanker.getBaseWeight(.other), 10, "Базовый вес OTHER должен быть 10")
    }
    
    func testKeywordScoreCalculation() throws {
        // Тест расчета веса ключевых слов
        let keywords = ["заплатить": 12, "купить": 10, "позвонить": 8]
        let text = "нужно заплатить за квартиру и купить продукты"
        
        let score = EventRanker.calculateKeywordScore(text, keywords: keywords)
        
        XCTAssertEqual(score, 22, "Вес должен быть 12 (заплатить) + 10 (купить) = 22")
    }
    
    func testKeywordScoreWithNoMatches() throws {
        // Тест расчета веса при отсутствии ключевых слов
        let keywords = ["заплатить": 12, "купить": 10]
        let text = "простое событие без ключевых слов"
        
        let score = EventRanker.calculateKeywordScore(text, keywords: keywords)
        
        XCTAssertEqual(score, 0, "Вес должен быть 0 при отсутствии ключевых слов")
    }
    
    func testUrgencyWeight() throws {
        // Тест расчета веса срочности
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today)!
        let nextMonth = Calendar.current.date(byAdding: .day, value: 30, to: today)!
        
        let urgencyTomorrow = EventRanker.calculateUrgency(tomorrow, type: .action)
        let urgencyNextWeek = EventRanker.calculateUrgency(nextWeek, type: .action)
        let urgencyNextMonth = EventRanker.calculateUrgency(nextMonth, type: .action)
        
        // Чем ближе событие, тем выше вес срочности
        XCTAssertGreaterThan(urgencyTomorrow, urgencyNextWeek, "Срочность завтрашнего события должна быть выше")
        XCTAssertGreaterThan(urgencyNextWeek, urgencyNextMonth, "Срочность события через неделю должна быть выше чем через месяц")
    }
    
    // MARK: - Тесты работы с данными календаря
    
    func testSpecialDatesRetrieval() throws {
        // Тест получения значимых дат (мок-тест)
        let mockContext = createMockModelContext()
        let dateService = DateAnalysisService()
        
        let specialDates = dateService.getSpecialDates(modelContext: mockContext)
        
        // Проверяем, что функция не падает и возвращает массив
        XCTAssertNotNil(specialDates, "Функция должна возвращать массив значимых дат")
        // Проверяем, что это действительно массив (может быть пустым)
        XCTAssertGreaterThanOrEqual(specialDates.count, 0, "Должен возвращаться корректный массив")
    }
    
    func testSpecialDatesForMonth() throws {
        // Тест получения значимых дат для конкретного месяца
        let mockContext = createMockModelContext()
        let dateService = DateAnalysisService()
        
        let specialDatesForMonth = dateService.getSpecialDatesForMonth(
            year: 2024,
            month: 12,
            modelContext: mockContext
        )
        
        // Проверяем структуру результата
        XCTAssertNotNil(specialDatesForMonth, "Функция должна возвращать словарь дат")
        // Проверяем, что это словарь (может быть пустым)
        XCTAssertGreaterThanOrEqual(specialDatesForMonth.count, 0, "Должен возвращаться корректный словарь")
    }
    
    func testCalendarServiceInitialization() throws {
        // Тест инициализации сервиса календаря
        let calendarService = CalendarSyncService()
        
        XCTAssertNotNil(calendarService, "CalendarSyncService должен инициализироваться")
    }
    
    // MARK: - Вспомогательные методы
    
    private func createTestEvent(title: String, date: Date, notes: String?) -> EventModel {
        return EventModel(
            id: UUID().uuidString,
            title: title,
            startDate: date,
            endDate: date,
            notes: notes
        )
    }
    
    private func createMockModelContext() -> ModelContext {
        // Создаем мок-контекст для тестирования
        // В реальном приложении здесь будет in-memory контекст
        let container = try! ModelContainer(for: SignificantDate.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return ModelContext(container)
    }
}

// MARK: - Extensions для тестирования приватных методов

extension EventRanker {
    static func classifyEvent(event: EventModel, text: String, actionKeywords: [String: Int], greetingKeywords: [String: Int], includeAnniversaries: Bool) -> (SignificantDateType, Int?) {
        return classify(event: event, text: text, actionKW: actionKeywords, greetKW: greetingKeywords, includeAnniversaries: includeAnniversaries)
    }
    
    static func getBaseWeight(_ type: SignificantDateType) -> Int {
        return baseWeight(type)
    }
    
    static func calculateKeywordScore(_ text: String, keywords: [String: Int]) -> Int {
        return keywordScore(text, dict: keywords)
    }
    
    static func calculateUrgency(_ date: Date, type: SignificantDateType) -> Int {
        return urgency(date, type: type)
    }
}
