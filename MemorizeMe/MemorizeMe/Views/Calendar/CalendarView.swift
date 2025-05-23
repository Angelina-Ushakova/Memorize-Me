import SwiftUI

struct CalendarView: View {
    // Принимаем ViewModel через параметр
    @ObservedObject var viewModel: CalendarViewModel
    
    // Локальное состояние для режима отображения
    @State private var displayMode: DisplayMode = .monthly
    
    // Определяем режимы отображения календаря
    enum DisplayMode {
        case monthly, yearly
    }
    
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
                MonthlyCalendarView(viewModel: viewModel)
            } else {
                YearlyCalendarView(viewModel: viewModel)
            }
            
            Spacer()
        }
        .background(Color("backgroundPrimary").edgesIgnoringSafeArea(.all))
    }
}

// MARK: - Segment Control
struct SegmentControl: View {
    @Binding var selection: CalendarView.DisplayMode
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("primaryLight6"))
                    .frame(width: geometry.size.width / 2)
                    .offset(x: selection == .monthly ? 0 : geometry.size.width / 2)
                    .animation(.spring(), value: selection)
                
                HStack(spacing: 0) {
                    Button(action: {
                        selection = .monthly
                    }) {
                        Text("Месяц")
                            .foregroundColor(Color("textPrimary"))
                            .frame(width: geometry.size.width / 2, height: geometry.size.height)
                            .font(.system(size: 16))
                    }
                    
                    Button(action: {
                        selection = .yearly
                    }) {
                        Text("Год")
                            .foregroundColor(Color("textPrimary"))
                            .frame(width: geometry.size.width / 2, height: geometry.size.height)
                            .font(.system(size: 16))
                    }
                }
            }
        }
        .frame(height: 40)
    }
}

#Preview {
    CalendarView(viewModel: CalendarViewModel())
}
