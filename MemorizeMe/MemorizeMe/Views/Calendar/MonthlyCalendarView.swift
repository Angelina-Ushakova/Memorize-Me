import SwiftUI
import SwiftData

struct MonthlyCalendarView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var significantDateViewModel: SignificantDateViewModel

    @State private var selectedSpecialDate: SignificantDate?
    @State private var showAlert = false

    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }

    private let weekdaySymbols = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    private let monthNames = ["Январь", "Февраль", "Март", "Апрель", "Май", "Июнь", "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"]

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button(action: { viewModel.moveToPrevoiusMonth() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.gray)
                }

                Spacer()

                Text(monthNames[viewModel.currentMonth-1] + " " + String(viewModel.currentYear))
                    .font(.headline)

                Spacer()

                Button(action: { viewModel.moveToNextMonth() }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 12)

            HStack {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .frame(maxWidth: 36)
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 8)

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(36)), count: 7), spacing: 10) {
                ForEach(0..<daysInMonthCount(), id: \.self) { index in
                    if let dayInfo = getDayInfo(at: index) {
                        let specialDates = viewModel.getSpecialDates(for: dayInfo.date)
                        Button(action: {
                            if let firstSpecial = specialDates.first {
                                selectedSpecialDate = firstSpecial
                                showAlert = true
                            } else if dayInfo.isCurrentMonth {
                                viewModel.selectedDate = dayInfo.date
                            }
                        }) {
                            Text("\(dayInfo.day)")
                                .font(.system(size: 16))
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(!specialDates.isEmpty ? Color(specialDates[0].type.calendarColor) : Color.clear)
                                )
                                .foregroundColor(!specialDates.isEmpty ? Color("textPrimary") :
                                    (isToday(dayInfo.date) ? Color("primaryColor") :
                                        (!dayInfo.isCurrentMonth ? .gray : .primary)))
                        }
                        .disabled(!dayInfo.isCurrentMonth)
                    } else {
                        Text("")
                            .frame(width: 36, height: 36)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color("backgroundPrimary"))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .padding(.horizontal)
        .overlay(
            Group {
                if showAlert, let date = selectedSpecialDate {
                    SpecialDateAlertView(
                        specialDate: date,
                        onDelete: {
                            showAlert = false
                            Task {
                                await significantDateViewModel.deleteSpecialDate(date, modelContext: modelContext)
                            }
                        },
                        onDismiss: { showAlert = false }
                    )
                }
            }
        )
    }

    private func daysInMonthCount() -> Int { 42 }

    private func getDayInfo(at index: Int) -> DayInfo? {
        let year = viewModel.currentYear
        let month = viewModel.currentMonth
        let dateComponents = DateComponents(year: year, month: month, day: 1)
        let firstDayOfMonth = calendar.date(from: dateComponents)!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let offsetDays = (firstWeekday - calendar.firstWeekday + 7) % 7

        if index < offsetDays {
            let day = calendar.date(byAdding: .day, value: index - offsetDays, to: firstDayOfMonth)!
            return DayInfo(date: day, day: calendar.component(.day, from: day), isCurrentMonth: false)
        }

        let dayOfMonth = index - offsetDays + 1
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)!.count

        if dayOfMonth <= daysInMonth {
            if let date = calendar.date(byAdding: .day, value: dayOfMonth - 1, to: firstDayOfMonth) {
                return DayInfo(date: date, day: dayOfMonth, isCurrentMonth: true)
            }
        }

        let nextMonthOffset = dayOfMonth - daysInMonth
        if let lastDayOfMonth = calendar.date(byAdding: .day, value: daysInMonth - 1, to: firstDayOfMonth),
           let date = calendar.date(byAdding: .day, value: nextMonthOffset, to: lastDayOfMonth) {
            return DayInfo(date: date, day: calendar.component(.day, from: date), isCurrentMonth: false)
        }

        return nil
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: Date())
    }
}

struct DayInfo {
    let date: Date
    let day: Int
    let isCurrentMonth: Bool
}
