import Foundation

struct ReminderPlanner {

    static func build(_ ranked: [RankedEvent]) -> [SignificantDate] {
        var results: [SignificantDate] = []
        let today = Calendar.current.startOfDay(for: Date())

        for r in ranked {
            guard let nDate = notificationDate(for: r) else { continue }
            // Добавляем только если уведомление не в прошлом
            if nDate < today { continue }

            let significantDate = SignificantDate(
                relatedEvent: r.event,
                type: r.type,
                typeData: r.typeData,
                notificationDate: nDate
            )
            results.append(significantDate)
        }

        let deduplicated = deduplicateNotifications(results)
        return deduplicated
    }

    private static func notificationDate(for r: RankedEvent) -> Date? {
        let today = Calendar.current.startOfDay(for: Date())
        let cal = Calendar.current

        switch r.type {
        case .greeting:
            return delta(from: r.event.startDate, weightedChoices: [(7, 0.2), (1, 0.5), (0, 0.3)])

        case .action:
            return delta(from: r.event.startDate, weightedChoices: [(3, 0.4), (1, 0.4), (0, 0.2)])

        case .anniversary:
            // годовщина: всегда ближайшая будущая, 08:00
            let baseDate = r.event.startDate
            let eventMonth = cal.component(.month, from: baseDate)
            let eventDay = cal.component(.day, from: baseDate)
            var nextAnniversary = cal.date(from: DateComponents(
                year: cal.component(.year, from: today),
                month: eventMonth,
                day: eventDay,
                hour: 8,
                minute: 0
            ))!
            if nextAnniversary < today {
                nextAnniversary = cal.date(byAdding: .year, value: 1, to: nextAnniversary)!
            }
            return nextAnniversary

        case .prettyDate:
            let startOfDay = cal.startOfDay(for: r.event.startDate)
            return cal.date(bySettingHour: 8, minute: 0, second: 0, of: startOfDay)

        case .throwback:
            // только для событий ≤ 365 дней назад, напоминание через 7 дней после события
            let throwbackDate = cal.date(byAdding: .day, value: 7, to: r.event.startDate)!
            // throwback только если дата не в прошлом и не дальше 1 года от сегодня
            if throwbackDate < today || throwbackDate > cal.date(byAdding: .day, value: 365, to: today)! {
                return nil
            }
            return throwbackDate

        case .other:
            return delta(from: r.event.startDate, weightedChoices: [(1, 0.34), (3, 0.33), (7, 0.33)])
        }
    }

    private static func delta(from date: Date, weightedChoices: [(Int, Double)]) -> Date? {
        guard let d = weightedRandom(weightedChoices) else { return nil }
        guard let res = Calendar.current.date(byAdding: .day, value: -d, to: date) else { return nil }
        return res >= Calendar.current.startOfDay(for: Date()) ? res : nil
    }

    private static func weightedRandom(_ choices: [(Int, Double)]) -> Int? {
        let total = choices.reduce(0) { $0 + $1.1 }
        let r = Double.random(in: 0...total)
        var acc = 0.0

        for (val, w) in choices {
            acc += w
            if r <= acc { return val }
        }
        return choices.first?.0
    }

    private static func deduplicateNotifications(_ notifications: [SignificantDate]) -> [SignificantDate] {
        var seen: [String: SignificantDate] = [:]
        for notification in notifications {
            let key = "\(Calendar.current.startOfDay(for: notification.notificationDate))_\(notification.eventTitle)"
            if seen[key] == nil {
                seen[key] = notification
            }
        }
        return Array(seen.values).sorted { $0.notificationDate < $1.notificationDate }
    }
}
