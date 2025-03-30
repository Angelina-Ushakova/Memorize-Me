import SwiftUI

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var displayMode: DisplayMode = .monthly
    @State private var currentMonth = Calendar.current.component(.month, from: Date())
    @State private var currentYear = Calendar.current.component(.year, from: Date())
    
    enum DisplayMode {
        case monthly, yearly
    }
    
    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Понедельник как первый день недели
        return calendar
    }
    
    private let weekdaySymbols = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    private let monthNames = ["Январь", "Февраль", "Март", "Апрель", "Май", "Июнь", "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"]
    
    var body: some View {
        VStack(spacing: 20) {
            // Заголовок посередине
            Text("Календарь")
                .font(.largeTitle)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top)
            
            // Кастомный сегмент-переключатель
            SegmentControl(selection: $displayMode)
                .frame(width: 280) // Ограничиваем ширину пикера
            
            // Отображаем календарь в зависимости от выбранного режима
            if displayMode == .monthly {
                monthlyCalendarView
            } else {
                Text("Годовой календарь в разработке")
                    .foregroundColor(.gray)
                    .padding()
            }
            
            Spacer()
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
    }
    
    private var monthlyCalendarView: some View {
        VStack(spacing: 10) {
            // Заголовок месяца с кнопками навигации
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(monthNames[currentMonth-1] + " " + String(currentYear))
                    .font(.headline)
                
                Spacer()
                
                Button(action: nextMonth) {
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
                                selectedDate = dayInfo.date
                            }
                        }) {
                            Text("\(dayInfo.day)")
                                .font(.system(size: 16))
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(isToday(dayInfo.date) ? Color.pink.opacity(0.3) : Color.clear)
                                )
                                .foregroundColor(dayInfo.isCurrentMonth ? .primary : .gray)
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
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    // Функция для получения количества ячеек в сетке календаря
    private func daysInMonthCount() -> Int {
        return 42 // 6 недель
    }
    
    // Функция для получения информации о дне по индексу
    private func getDayInfo(at index: Int) -> DayInfo? {
        let year = currentYear
        let month = currentMonth
        
        let dateComponents = DateComponents(year: year, month: month, day: 1)
        let firstDayOfMonth = calendar.date(from: dateComponents)!
        
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
    
    // Структура для информации о дне
    private struct DayInfo {
        let date: Date
        let day: Int
        let isCurrentMonth: Bool
    }
    
    // Проверка, является ли дата сегодняшней
    private func isToday(_ date: Date) -> Bool {
        return calendar.isDate(date, inSameDayAs: Date())
    }
    
    // Переход к предыдущему месяцу
    private func previousMonth() {
        if currentMonth == 1 {
            currentMonth = 12
            currentYear -= 1
        } else {
            currentMonth -= 1
        }
    }
    
    // Переход к следующему месяцу
    private func nextMonth() {
        if currentMonth == 12 {
            currentMonth = 1
            currentYear += 1
        } else {
            currentMonth += 1
        }
    }
}

struct SegmentControl: View {
    @Binding var selection: CalendarView.DisplayMode
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Фон
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                
                // Индикатор выбранного элемента
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.pink.opacity(0.3))
                    .frame(width: geometry.size.width / 2)
                    .offset(x: selection == .monthly ? 0 : geometry.size.width / 2)
                    .animation(.spring(), value: selection)
                
                // Кнопки
                HStack(spacing: 0) {
                    Button(action: {
                        selection = .monthly
                    }) {
                        Text("Месяц")
                            .foregroundColor(.black) // Всегда черный цвет
                            .frame(width: geometry.size.width / 2, height: geometry.size.height)
                            .font(.system(size: 16))
                    }
                    
                    Button(action: {
                        selection = .yearly
                    }) {
                        Text("Год")
                            .foregroundColor(.black) // Всегда черный цвет
                            .frame(width: geometry.size.width / 2, height: geometry.size.height)
                            .font(.system(size: 16))
                    }
                }
            }
        }
        .frame(height: 40) // Уменьшенная высота
    }
}

#Preview {
    CalendarView()
}
