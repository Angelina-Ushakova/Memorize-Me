import SwiftUI
import UIKit

struct MainTabView: View {
    @Binding var accessGranted: Bool?
    
    @StateObject private var calendarViewModel = CalendarViewModel()
    
    var body: some View {
        TabViewWithLine {
            TabView {
                // Вкладка календаря
                CalendarView(viewModel: calendarViewModel)
                    .tabItem {
                        Label("Календарь", systemImage: "calendar")
                    }
                    .onAppear {
                        calendarViewModel.initialize()
                    }
                
                // Вкладка настроек
                SettingsView(
                    viewModel: SettingsViewModel(
                        isCalendarAccessGranted: accessGranted ?? false
                    ),
                    accessGranted: Binding<Bool>(
                        get: { self.accessGranted ?? false },
                        set: { self.accessGranted = $0 }
                    )
                )
                .tabItem {
                    Label("Настройки", systemImage: "gear")
                }
            }
            .accentColor(Color("primaryColor"))
        }
    }
}
