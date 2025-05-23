import SwiftUI

struct MonthlyCalendarView: View {
    @ObservedObject var viewModel: CalendarViewModel
    
    // Создаем календарь с понедельником как началом недели
    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Понедельник как первый день недели
        return calendar
    }
    
    // Массивы для локализованных названий
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
            
            // Дни недели
            HStack {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .frame(maxWidth: 36)
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 8)
            
            // Календарная сетка
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(36)), count: 7), spacing: 10) {
                ForEach(0..<daysInMonthCount(), id: \.self) { index in
                    if let dayInfo = getDayInfo(at: index) {
                        Button(action: {
                            if dayInfo.isCurrentMonth {
                                viewModel.selectedDate = dayInfo.date
                            }
                        }) {
                            Text("\(dayInfo.day)")
                                .font(.system(size: 16))
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(isToday(dayInfo.date) ? Color("primaryLight6") : Color.clear)
                                )
                                .foregroundColor(dayInfo.isCurrentMonth ? (isToday(dayInfo.date) ? Color("textPrimary") : .primary) : .gray)
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
    }
    
    // MARK: - Helper Functions
    
    // Функция для получения количества ячеек в сетке календаря
    private func daysInMonthCount() -> Int {
        return 42 // 6 недель
    }
    
    // Функция для получения информации о дне по индексу
    private func getDayInfo(at index: Int) -> DayInfo? {
        let year = viewModel.currentYear
        let month = viewModel.currentMonth
        
        // Получаем первый день текущего месяца
        let dateComponents = DateComponents(year: year, month: month, day: 1)
        let firstDayOfMonth = calendar.date(from: dateComponents)!
        
        // Вычисляем смещение первого дня месяца
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let offsetDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        // Если индекс меньше смещения, нужно показать дни предыдущего месяца
        if index < offsetDays {
            let day = calendar.date(byAdding: .day, value: index - offsetDays, to: firstDayOfMonth)!
            return DayInfo(
                date: day,
                day: calendar.component(.day, from: day),
                isCurrentMonth: false
            )
        }
        
        // Вычисляем текущий день месяца
        let dayOfMonth = index - offsetDays + 1
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)!.count
        
        // Если индекс соответствует текущему месяцу
        if dayOfMonth <= daysInMonth {
            if let date = calendar.date(byAdding: .day, value: dayOfMonth - 1, to: firstDayOfMonth) {
                return DayInfo(
                    date: date,
                    day: dayOfMonth,
                    isCurrentMonth: true
                )
            }
        }
        
        // Если индекс больше, чем дней в текущем месяце, показываем дни следующего месяца
        let nextMonthOffset = dayOfMonth - daysInMonth
        if let lastDayOfMonth = calendar.date(byAdding: .day, value: daysInMonth - 1, to: firstDayOfMonth),
           let date = calendar.date(byAdding: .day, value: nextMonthOffset, to: lastDayOfMonth) {
            return DayInfo(
                date: date,
                day: calendar.component(.day, from: date),
                isCurrentMonth: false
            )
        }
        
        return nil
    }
    
    // Проверка, является ли дата сегодняшней
    private func isToday(_ date: Date) -> Bool {
        return calendar.isDate(date, inSameDayAs: Date())
    }
}

// MARK: - Supporting Types
struct DayInfo {
    let date: Date
    let day: Int
    let isCurrentMonth: Bool
}

#Preview {
    MonthlyCalendarView(viewModel: CalendarViewModel())
}
