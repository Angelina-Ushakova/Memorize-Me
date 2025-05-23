import SwiftUI

struct YearlyCalendarView: View {
    @ObservedObject var viewModel: CalendarViewModel

    @State private var eventsByDate: [Date: [EventModel]] = [:]
    @State private var didScrollToCurrentMonth = false
    @State private var lastScrolledYear: Int = Calendar.current.component(.year, from: Date())

    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }

    private let monthNames = ["Январь", "Февраль", "Март", "Апрель", "Май", "Июнь", "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"]
    private let weekdaySymbols = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button(action: {
                    viewModel.currentYear -= 1
                    eventsByDate = viewModel.getEventsForYear(year: viewModel.currentYear)
                    didScrollToCurrentMonth = false // сбросить для нового года
                    lastScrolledYear = viewModel.currentYear
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                }
                Spacer()
                Text(String(viewModel.currentYear))
                    .font(.headline)
                Spacer()
                Button(action: {
                    viewModel.currentYear += 1
                    eventsByDate = viewModel.getEventsForYear(year: viewModel.currentYear)
                    didScrollToCurrentMonth = false // сбросить для нового года
                    lastScrolledYear = viewModel.currentYear
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                }
            }
            .padding(.top, 8)

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(1...12, id: \.self) { month in
                            YearlyMonthView(
                                year: viewModel.currentYear,
                                month: month,
                                isCurrentMonth: isCurrentMonth(month: month, year: viewModel.currentYear),
                                calendar: calendar,
                                monthNames: monthNames,
                                weekdaySymbols: weekdaySymbols,
                                eventsByDate: eventsByDate
                            )
                            .id(month)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .onAppear {
                    eventsByDate = viewModel.getEventsForYear(year: viewModel.currentYear)
                    // Только при первом открытии года автоскроллим к текущему месяцу
                    if !didScrollToCurrentMonth && viewModel.currentYear == Calendar.current.component(.year, from: Date()) {
                        let nowMonth = Calendar.current.component(.month, from: Date())
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                proxy.scrollTo(nowMonth, anchor: .center)
                            }
                            didScrollToCurrentMonth = true
                            lastScrolledYear = viewModel.currentYear
                        }
                    }
                }
                // Если View уже появилась и пользователь меняет год, скролл произойдет ОДИН раз для нового года
                .onChange(of: viewModel.currentYear) { newYear in
                    eventsByDate = viewModel.getEventsForYear(year: newYear)
                    if !didScrollToCurrentMonth && newYear == Calendar.current.component(.year, from: Date()) {
                        let nowMonth = Calendar.current.component(.month, from: Date())
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                proxy.scrollTo(nowMonth, anchor: .center)
                            }
                            didScrollToCurrentMonth = true
                            lastScrolledYear = newYear
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color("backgroundPrimary"))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private func isCurrentMonth(month: Int, year: Int) -> Bool {
        let now = Date()
        let nowMonth = Calendar.current.component(.month, from: now)
        let nowYear = Calendar.current.component(.year, from: now)
        return month == nowMonth && year == nowYear
    }
}

// MARK: - Yearly Month View
struct YearlyMonthView: View {
    let year: Int
    let month: Int
    let isCurrentMonth: Bool
    let calendar: Calendar
    let monthNames: [String]
    let weekdaySymbols: [String]
    let eventsByDate: [Date: [EventModel]]

    var body: some View {
        VStack(spacing: 8) {
            // Название месяца, просто для красоты
            Text(monthNames[month-1])
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(isCurrentMonth ? Color("primaryColor") : .primary)
                .padding(.vertical, 8)

            HStack {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .frame(maxWidth: 28)
                        .foregroundColor(.gray)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(28)), count: 7), spacing: 4) {
                ForEach(0..<42, id: \.self) { index in
                    if let dayInfo = getYearlyDayInfo(at: index) {
                        // Проверяем есть ли событие в этот день
                        let hasEvent = eventsByDate.keys.contains(where: { calendar.isDate($0, inSameDayAs: dayInfo.date) })
                        ZStack {
                            Text("\(dayInfo.day)")
                                .font(.system(size: 12))
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle()
                                        .fill(isToday(dayInfo.date) ? Color("primaryLight6") : Color.clear)
                                )
                                .foregroundColor(dayInfo.isCurrentMonth ? (isToday(dayInfo.date) ? Color("textPrimary") : .primary) : .gray)
                            if hasEvent {
                                Circle()
                                    .fill(Color("primaryColor"))
                                    .frame(width: 5, height: 5)
                                    .offset(y: 10)
                            }
                        }
                    } else {
                        Text("")
                            .frame(width: 28, height: 28)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isCurrentMonth ? Color("primaryLight6").opacity(0.2) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCurrentMonth ? Color("primaryColor").opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }

    private func getYearlyDayInfo(at index: Int) -> DayInfo? {
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

#Preview {
    YearlyCalendarView(viewModel: CalendarViewModel())
}
