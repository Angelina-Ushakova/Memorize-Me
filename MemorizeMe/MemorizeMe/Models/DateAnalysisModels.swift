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
    static func topSpecials(from events: [EventModel], window: DateInterval, maxCount: Int = 20) -> [RankedEvent] {
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

            // Упростим: для throwback достаточно 25 баллов, для остальных 30
            let minScore = (type == .throwback ? 25 : 30)
            guard score >= minScore else { continue }
            output.append(.init(event: e, type: type, typeData: typeData, score: score))
        }

        let result = output.sorted { $0.score > $1.score }.map { $0 }

        print("Отобрано \(result.count) значимых событий")
        return result
    }

    private static func classify(event: EventModel, text: String, actionKW: [String: Int], greetKW: [String: Int]) -> (SignificantDateType, Int?) {
        let today = Calendar.current.startOfDay(for: Date())

        // throwback: событие прошло ≤ 365 дней назад
        if event.startDate < today {
            let daysBetween = Calendar.current.dateComponents([.day], from: event.startDate, to: today).day ?? 0
            if daysBetween <= 365 && daysBetween > 0 {
                return (.throwback, daysBetween)
            }
        }
        // anniversary: событие прошло 1+ лет назад
        if event.startDate < today {
            let years = Calendar.current.dateComponents([.year], from: event.startDate, to: today).year ?? 0
            if years >= 1 {
                return (.anniversary, years)
            }
        }
        if greetKW.keys.contains(where: text.contains) {
            return (.greeting, nil)
        }
        if actionKW.keys.contains(where: text.contains) {
            return (.action, nil)
        }
        if isPrettyDate(event.startDate) {
            return (.prettyDate, nil)
        }
        return (.other, nil)
    }

    private static func baseWeight(_ type: SignificantDateType) -> Int {
        switch type {
        case .greeting:     return 40
        case .action:       return 30
        case .anniversary:  return 28
        case .prettyDate:   return 22
        case .throwback:    return 25
        case .other:        return 10
        }
    }

    private static func keywordScore(_ text: String, dict: [String: Int]) -> Int {
        return dict.reduce(0) { total, pair in
            total + (text.contains(pair.key) ? pair.value : 0)
        }
    }

    private static func urgency(_ date: Date, type: SignificantDateType) -> Int {
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
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        let dayStr = String(format: "%02d", day)
        let monthStr = String(format: "%02d", month)
        let yearStr = String(year)

        // День == месяц
        if day == month { return true }
        // Зеркальные: 01.10, 10.01, 12.21, 21.12
        if dayStr == String(monthStr.reversed()) { return true }
        // Одинаковые цифры в дне и месяце (например, 11.22, 22.11, 11.11, 22.22)
        if dayStr.count == 2 && monthStr.count == 2 {
            let dayFirst = dayStr[dayStr.startIndex]
            let daySecond = dayStr[dayStr.index(dayStr.startIndex, offsetBy: 1)]
            let monthFirst = monthStr[monthStr.startIndex]
            let monthSecond = monthStr[monthStr.index(monthStr.startIndex, offsetBy: 1)]
            if dayFirst == daySecond && monthFirst == monthSecond {
                return true
            }
        }
        // Год совпадает с днем или месяцем (например, 10.10.2010, 12.12.2012)
        if yearStr.hasSuffix(dayStr) || yearStr.hasSuffix(monthStr) { return true }
        // Примеры из ПЗ (на всякий случай)
        let fmt = DateFormatter()
        fmt.dateFormat = "dd.MM"
        let part = fmt.string(from: date)
        let prettyPatterns = ["11.11", "22.02", "12.12", "02.02", "01.01", "10.10", "03.03", "04.04", "05.05", "06.06", "07.07", "08.08", "09.09"]
        if prettyPatterns.contains(part) { return true }

        return false
    }
}
