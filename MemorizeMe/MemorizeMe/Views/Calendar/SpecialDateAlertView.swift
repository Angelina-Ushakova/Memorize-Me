import SwiftUI

struct SpecialDateAlertView: View {
    let specialDate: SignificantDate
    var onDelete: (() -> Void)?
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 32))
                    .foregroundColor(Color(specialDate.type.calendarColor))
                Spacer()
                Text(specialDate.type.description)
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.trailing, 2)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(specialDate.eventTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                Text("Дата события: \(formatDate(specialDate.eventStartDate))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if let notes = specialDate.eventNotes, !notes.isEmpty {
                    Text(notes)
                        .font(.body)
                        .padding(.top, 2)
                }
                Text("Дата напоминания: \(formatDateTime(specialDate.notificationDate))")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Button {
                    onDelete?()
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Удалить")
                    }
                }
                .foregroundColor(.red)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)

                Divider().frame(height: 30)

                Button {
                    onDismiss?()
                } label: {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Окей")
                    }
                }
                .foregroundColor(.accentColor)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
            }
            .font(.body)
            .padding(.top, 8)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(specialDate.type.calendarColor), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.13), radius: 16, x: 0, y: 6) // как на календаре
        .padding(.horizontal, 24)
    }

    private var iconName: String {
        switch specialDate.type {
        case .action: return "checkmark.circle"
        case .greeting: return "gift"
        case .anniversary: return "calendar.badge.clock"
        case .prettyDate: return "sparkles"
        case .throwback: return "clock.arrow.circlepath"
        case .other: return "calendar"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.dateStyle = .medium
        return df.string(from: date)
    }
    private func formatDateTime(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: date)
    }
}
