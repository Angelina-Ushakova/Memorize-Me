import Foundation

struct RankedEvent {
    let event: EventModel
    let type: SignificantDateType
    let typeData: Int?
    let score: Int
}

struct KeywordLoader {
    static func load(_ name: String) -> [String: Int] {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: Int].self, from: data)
        else {
            print("Ошибка загрузки \(name).json")
            return [:]
        }
        return dict.mapKeys { $0.lowercased() }
    }
}

private extension Dictionary {
    func mapKeys<T>(_ transform: (Key) -> T) -> [T: Value] {
        var output: [T: Value] = [:]
        for (k, v) in self {
            output[transform(k)] = v
        }
        return output
    }
}

struct EventRanker {
    
    static func topSpecials(from events: [EventModel],
                           window: DateInterval,
                           maxCount: Int = 20) -> [RankedEvent] {
        
        let actionKW = KeywordLoader.load("action_verbs")
        let greetKW = KeywordLoader.load("greeting_keywords")
        var output: [RankedEvent] = []
        
        print("Анализируем \(events.count) событий")
        
        for e in events where window.contains(e.startDate) {
            let text = (e.title + " " + (e.notes ?? "")).lowercased()
            
            let (type, typeData) = classify(event: e, text: text, actionKW: actionKW, greetKW: greetKW)
            
            var score = baseWeight(type)
            score += keywordScore(text, dict: (type == .greeting ? greetKW : actionKW))
            score += urgency(e.startDate, type: type)
            score += randomBoost(e.id)
            
            guard score >= 30 else { continue }
            output.append(.init(event: e, type: type, typeData: typeData, score: score))
        }
        
        let result = output.sorted { $0.score > $1.score }
                           .prefix(maxCount)
                           .map { $0 }
        
        print("Отобрано \(result.count) значимых событий")
        return result
    }
    
    private static func classify(event: EventModel, text: String, actionKW: [String: Int], greetKW: [String: Int]) -> (SignificantDateType, Int?) {
        
        let today = Date()
        
        // Проверяем throwback (событие было ≤ 365 дней назад)
        if event.startDate < today {
            let daysBetween = Calendar.current.dateComponents([.day], from: event.startDate, to: today).day ?? 0
            if daysBetween <= 365 && daysBetween > 0 {
                return (.throwback, daysBetween)
            }
        }
        
        // Проверяем anniversary (круглое число лет)
        if event.startDate < today {
            let years = Calendar.current.dateComponents([.year], from: event.startDate, to: today).year ?? 0
            if years >= 1 {
                return (.anniversary, years)
            }
        }
        
        // Проверяем ключевые слова
        if greetKW.keys.contains(where: text.contains) {
            return (.greeting, nil)
        }
        if actionKW.keys.contains(where: text.contains) {
            return (.action, nil)
        }
        
        // Проверяем красивую дату
        if isPrettyDate(event.startDate) {
            return (.prettyDate, nil)
        }
        
        return (.other, nil)
    }
    
    private static func baseWeight(_ type: SignificantDateType) -> Int {
        switch type {
        case .greeting:     return 40
        case .action:       return 30
        case .anniversary:  return 25
        case .prettyDate:   return 20
        case .throwback:    return 18
        case .other:        return 10
        }
    }
    
    private static func keywordScore(_ text: String, dict: [String: Int]) -> Int {
        return dict.reduce(0) { total, pair in
            total + (text.contains(pair.key) ? pair.value : 0)
        }
    }
    
    private static func urgency(_ date: Date, type: SignificantDateType) -> Int {
        guard type != .throwback else { return 0 }
        let days = max(0, min(30, daysBetween(Date(), date)))
        return 15 - days / 2
    }
    
    private static func randomBoost(_ id: String) -> Int {
        return abs(id.hashValue) % 10
    }
    
    private static func daysBetween(_ a: Date, _ b: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: a, to: b).day ?? 0
    }
    
    private static func isPrettyDate(_ date: Date) -> Bool {
        let fmt = DateFormatter()
        fmt.dateFormat = "dd.MM"
        let part = fmt.string(from: date)
        
        let prettyPatterns = ["11.11", "22.02", "12.12", "02.02", "01.01", "10.10", "03.03", "04.04", "05.05", "06.06", "07.07", "08.08", "09.09"]
        return prettyPatterns.contains(part)
    }
}
