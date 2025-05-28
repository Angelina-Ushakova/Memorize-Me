import SwiftUI
import SwiftData

struct MonthlyCalendarView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var significantDateViewModel: SignificantDateViewModel
    
    @State private var selectedSpecialDates: [SignificantDate] = []
    @State private var showAlert = false
    @State private var showMultipleAlert = false
    
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
                            if specialDates.count > 1 {
                                selectedSpecialDates = specialDates
                                showMultipleAlert = true
                            } else if let firstSpecial = specialDates.first {
                                selectedSpecialDates = [firstSpecial]
                                showAlert = true
                            } else if dayInfo.isCurrentMonth {
                                viewModel.selectedDate = dayInfo.date
                            }
                        }) {
                            ZStack {
                                // Фон для событий
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
                                    // Для 3+ событий используем специальный многоцветный индикатор
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
                                
                                Text("\(dayInfo.day)")
                                    .font(.system(size: 16))
                                    .foregroundColor(!specialDates.isEmpty ? Color("textPrimary") :
                                                        (isToday(dayInfo.date) ? Color("primaryColor") :
                                                            (!dayInfo.isCurrentMonth ? .gray : .primary)))
                                
                                // Индикатор количества событий
                                if specialDates.count > 1 {
                                    VStack {
                                        HStack {
                                            Spacer()
                                            Text("\(specialDates.count)")
                                                .font(.system(size: 8, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(2)
                                                .background(Circle().fill(Color.black.opacity(0.6)))
                                                .offset(x: 4, y: -4)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                            .frame(width: 36, height: 36)
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

struct MultipleDatesAlertView: View {
    let specialDates: [SignificantDate]
    var onSelect: ((SignificantDate) -> Void)?
    var onDismiss: (() -> Void)?
    
    @State private var windowSize: CGSize = .zero
    
    var body: some View {
        VStack(spacing: 0) {
            // Заголовок
            HStack {
                Text("Несколько напоминаний")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { onDismiss?() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            .padding(20)
            
            Divider()
            
            // Список событий
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(specialDates, id: \.id) { special in
                        Button(action: { onSelect?(special) }) {
                            HStack(spacing: 12) {
                                Image(systemName: iconName(for: special.type))
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(special.type.calendarColor))
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(special.eventTitle)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                    
                                    Text(special.type.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            .padding(12)
                            .background(Color("backgroundPrimary"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(special.type.calendarColor), lineWidth: 1.5)
                            )
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(20)
                .padding(.top, -10)
            }
        }
        .frame(width: 320, height: 320)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.systemGray3), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.13), radius: 16, x: 0, y: 6)
        .padding(.horizontal, 32)
        
    }
    
    private func iconName(for type: SignificantDateType) -> String {
        switch type {
        case .action: return "checkmark.circle"
        case .greeting: return "gift"
        case .anniversary: return "calendar.badge.clock"
        case .prettyDate: return "sparkles"
        case .throwback: return "clock.arrow.circlepath"
        case .other: return "calendar"
            
        }
    }
}
