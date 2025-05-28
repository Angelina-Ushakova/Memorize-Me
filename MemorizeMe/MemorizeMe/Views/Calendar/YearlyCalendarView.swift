import SwiftUI
import SwiftData

struct YearlyCalendarView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var significantDateViewModel: SignificantDateViewModel

    @State private var specialDatesByDate: [Date: [SignificantDate]] = [:]
    @State private var didScrollToCurrentMonth = false
    @State private var lastScrolledYear: Int = Calendar.current.component(.year, from: Date())

    @State private var selectedSpecialDates: [SignificantDate] = []
    @State private var showAlert = false
    @State private var showMultipleAlert = false

    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }

    private let monthNames = ["Январь", "Февраль", "Март", "Апрель", "Май", "Июнь", "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"]
    private let weekdaySymbols = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

    var body: some View {
        ZStack {
            VStack(spacing: 10) {
                HStack {
                    Button(action: {
                        viewModel.currentYear -= 1
                        specialDatesByDate = viewModel.getSpecialDatesForYear(year: viewModel.currentYear, modelContext: modelContext)
                        didScrollToCurrentMonth = false
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
                        specialDatesByDate = viewModel.getSpecialDatesForYear(year: viewModel.currentYear, modelContext: modelContext)
                        didScrollToCurrentMonth = false
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
                                    specialDatesByDate: specialDatesByDate,
                                    onSelectSpecialDates: { dates in
                                        if dates.count > 1 {
                                            selectedSpecialDates = dates
                                            showMultipleAlert = true
                                        } else if let first = dates.first {
                                            selectedSpecialDates = [first]
                                            showAlert = true
                                        }
                                    }
                                )
                                .id(month)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onAppear {
                        specialDatesByDate = viewModel.getSpecialDatesForYear(year: viewModel.currentYear, modelContext: modelContext)
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
                    .onChange(of: viewModel.currentYear) { newYear in
                        specialDatesByDate = viewModel.getSpecialDatesForYear(year: newYear, modelContext: modelContext)
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

            if showAlert, let date = selectedSpecialDates.first {
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
            
            if showMultipleAlert {
                MultipleDatesAlertView(
                    specialDates: selectedSpecialDates,
                    onSelect: { selected in
                        showMultipleAlert = false
                        selectedSpecialDates = [selected]
                        showAlert = true
                    },
                    onDismiss: { showMultipleAlert = false }
                )
            }
        }
    }

    private func isCurrentMonth(month: Int, year: Int) -> Bool {
        let now = Date()
        let nowMonth = Calendar.current.component(.month, from: now)
        let nowYear = Calendar.current.component(.year, from: now)
        return month == nowMonth && year == nowYear
    }
}

struct YearlyMonthView: View {
    let year: Int
    let month: Int
    let isCurrentMonth: Bool
    let calendar: Calendar
    let monthNames: [String]
    let weekdaySymbols: [String]
    let specialDatesByDate: [Date: [SignificantDate]]
    var onSelectSpecialDates: ([SignificantDate]) -> Void

    var body: some View {
        VStack(spacing: 8) {
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

            let daysInMonth = numberOfDaysInMonth(year: year, month: month)
            let firstDayOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
            let weekdayOfFirstDay = calendar.component(.weekday, from: firstDayOfMonth)
            let offsetDays = (weekdayOfFirstDay - calendar.firstWeekday + 7) % 7

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(28)), count: 7), spacing: 4) {
                ForEach(0..<offsetDays, id: \.self) { _ in
                    Text("")
                        .frame(width: 28, height: 28)
                }
                
                ForEach(1...daysInMonth, id: \.self) { day in
                    let date = calendar.date(from: DateComponents(year: year, month: month, day: day))!
                    let specialDates = specialDatesByDate.filter { calendar.isDate($0.key, inSameDayAs: date) }.flatMap { $0.value }
                    
                    Button(action: {
                        if !specialDates.isEmpty {
                            onSelectSpecialDates(specialDates)
                        }
                    }) {
                        ZStack {
                            if specialDates.count == 1 {
                                Circle()
                                    .fill(Color(specialDates[0].type.calendarColor))
                            } else if specialDates.count == 2 {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(specialDates[0].type.calendarColor),
                                                Color(specialDates[1].type.calendarColor)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            } else if specialDates.count > 2 {
                                // Многоцветный градиент для 3+ событий
                                Circle()
                                    .fill(
                                        AngularGradient(
                                            gradient: Gradient(colors: [
                                                Color("primaryLight6"),
                                                Color("lightOrange"),
                                                Color("lightPurple"),
                                                Color("primaryLight6")
                                            ]),
                                            center: .center
                                        )
                                    )
                            }
                            
                            Text("\(day)")
                                .font(.system(size: 12))
                                .foregroundColor(
                                    !specialDates.isEmpty ? Color("textPrimary") :
                                    isToday(date) ? Color("primaryColor") : .primary
                                )
                            
                            if specialDates.count > 1 {
                                VStack {
                                    HStack {
                                        Spacer()
                                        Text("\(specialDates.count)")
                                            .font(.system(size: 6, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(1)
                                            .background(Circle().fill(Color.black.opacity(0.6)))
                                            .offset(x: 2, y: -2)
                                    }
                                    Spacer()
                                }
                            }
                        }
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

    private func isToday(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: Date())
    }

    private func numberOfDaysInMonth(year: Int, month: Int) -> Int {
        let components = DateComponents(year: year, month: month)
        let calendar = Calendar.current
        let date = calendar.date(from: components)!
        return calendar.range(of: .day, in: .month, for: date)!.count
    }
}
