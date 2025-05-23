import WidgetKit
import SwiftUI

func colorForType(_ type: String?) -> String {
    switch type {
    case "Поздравление": return "primaryLight6"
    case "Годовщина": return "lightGreen"
    case "Важное событие": return "lightRed"
    case "Приятная дата": return "lightPurple"
    case "Воспоминание": return "lightBlue"
    case "Другое": return "lightOrange"
    default: return "primaryLight6"
    }
}

struct MemorizeMeWidgetEntry: TimelineEntry {
    let date: Date
    let reminders: [ReminderForWidget]
}

struct ReminderForWidget {
    let title: String
    let type: String
    let date: Date
    let typeColor: String
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> MemorizeMeWidgetEntry {
        let sample = ReminderForWidget(title: "Поздравить Машу", type: "Поздравление", date: Date(), typeColor: "primaryLight6")
        return MemorizeMeWidgetEntry(date: Date(), reminders: [sample])
    }

    func getSnapshot(in context: Context, completion: @escaping (MemorizeMeWidgetEntry) -> ()) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MemorizeMeWidgetEntry>) -> ()) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    func loadEntry() -> MemorizeMeWidgetEntry {
        let userDefaults = UserDefaults(suiteName: "group.edu.hse.Ushakova.MemorizeMe")
        var reminders: [ReminderForWidget] = []
        for idx in 0..<2 {
            let title = userDefaults?.string(forKey: "widgetTitle\(idx)") ?? (idx == 0 ? userDefaults?.string(forKey: "widgetTitle") : nil)
            let type = userDefaults?.string(forKey: "widgetType\(idx)") ?? (idx == 0 ? userDefaults?.string(forKey: "widgetType") : nil)
            let timestamp = userDefaults?.double(forKey: "widgetDate\(idx)") ?? (idx == 0 ? userDefaults?.double(forKey: "widgetDate") : nil)
            if let title = title, let type = type, let ts = timestamp, ts > 0 {
                let date = Date(timeIntervalSince1970: ts)
                reminders.append(ReminderForWidget(title: title, type: type, date: date, typeColor: colorForType(type)))
            }
        }
        if reminders.isEmpty {
            reminders = [ReminderForWidget(title: "Нет напоминаний", type: "Другое", date: Date(), typeColor: "primaryLight6")]
        }
        return MemorizeMeWidgetEntry(date: Date(), reminders: reminders)
    }
}

struct MemorizeMeWidgetEntryView: View {
    var entry: MemorizeMeWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            Link(destination: URL(string: "memorizeMe://specialdates")!) {
                OneReminderWidgetView(reminder: entry.reminders.first!)
                    .padding(6)
                    .background(Color("backgroundPrimary"))
            }
        case .systemMedium:
            Link(destination: URL(string: "memorizeMe://specialdates")!) {
                VStack(spacing: 14) { // увеличенный отступ между карточками
                    ForEach(Array(entry.reminders.prefix(2).enumerated()), id: \.offset) { _, reminder in
                        ReminderCardForWidget(reminder: reminder)
                    }
                }
                .padding(10)
                .background(Color("backgroundPrimary"))
            }
        default:
            OneReminderWidgetView(reminder: entry.reminders.first!)
                .padding(6)
                .background(Color("backgroundPrimary"))
        }
    }
}

struct OneReminderWidgetView: View {
    let reminder: ReminderForWidget

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(reminder.type)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(Color(reminder.typeColor))
                .padding(.horizontal, 7)
                .padding(.vertical, 2.5)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Color(reminder.typeColor), lineWidth: 1)
                        .background(
                            Color("backgroundPrimary").clipShape(RoundedRectangle(cornerRadius: 7))
                        )
                )
            Text(formatShortDate(reminder.date))
                .font(.callout)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.top, 1)
            Text(reminder.title)
                .font(.footnote)
                .fontWeight(.regular)
                .foregroundColor(Color("textPrimary"))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
        }
        .padding(5)
        .background(Color("backgroundPrimary"))
    }
}

struct ReminderCardForWidget: View {
    let reminder: ReminderForWidget

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(reminder.type)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(reminder.typeColor))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color(reminder.typeColor), lineWidth: 1)
                            .background(
                                Color("backgroundPrimary").clipShape(RoundedRectangle(cornerRadius: 7))
                            )
                    )
                Spacer()
                Text(formatShortDate(reminder.date))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Text(reminder.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color("textPrimary"))
                .lineLimit(2)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 13)
                .stroke(Color(.systemGray4), lineWidth: 1)
                .background(Color("backgroundPrimary").clipShape(RoundedRectangle(cornerRadius: 13)))
        )
    }
}

func formatShortDate(_ date: Date) -> String {
    let df = DateFormatter()
    df.locale = Locale(identifier: "ru_RU")
    df.dateFormat = "d MMMM"
    return df.string(from: date)
}

struct MemorizeMeWidget: Widget {
    let kind: String = "MemorizeMeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MemorizeMeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Ближайшие напоминания")
        .description("Показывает ваши ближайшие важные напоминания.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
