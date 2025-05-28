import SwiftUI
import SwiftData
import UIKit

struct MainTabView: View {
    @Binding var accessGranted: Bool?
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var significantDateViewModel: SignificantDateViewModel
    
    @StateObject private var calendarViewModel = CalendarViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel(isCalendarAccessGranted: true) // Создаём один экземпляр
    
    var body: some View {
        TabViewWithLine {
            TabView {
                // Вкладка календаря
                CalendarView(viewModel: calendarViewModel)
                    .tabItem {
                        Label("Календарь", systemImage: "calendar")
                    }
                    .onAppear {
                        calendarViewModel.initialize(modelContext: modelContext)
                    }
                    .onChange(of: calendarViewModel.currentMonth) { _, _ in
                        calendarViewModel.loadSpecialDatesForCurrentMonth(modelContext: modelContext)
                    }
                    .onChange(of: calendarViewModel.currentYear) { _, _ in
                        calendarViewModel.loadSpecialDatesForCurrentMonth(modelContext: modelContext)
                    }
                
                // Вкладка значимых дат
                SpecialDatesView()
                    .tabItem {
                        Label("Напоминания", systemImage: "bell.badge")
                    }
                
                // Вкладка настроек
                SettingsViewWithNavigation(
                    viewModel: settingsViewModel,
                    accessGranted: Binding<Bool>(
                        get: { self.accessGranted ?? false },
                        set: { self.accessGranted = $0 }
                    )
                )
                .tabItem {
                    Label("Настройки", systemImage: "gear")
                }
            }
            .accentColor(Color("appPrimaryColor"))
        }
    }
}
