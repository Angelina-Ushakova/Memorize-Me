import SwiftUI
import EventKit

struct RootView: View {
    @State private var accessGranted: Bool? = nil
    let calendarService = CalendarSyncService()

    var body: some View {
        if let accessGranted = accessGranted {
            if accessGranted {
                MainTabView(accessGranted: $accessGranted)
            } else {
                AccessDeniedView()
            }
        } else {
            RequestCalendarAccessView(accessGranted: $accessGranted)
                .onAppear {
                    checkInitialCalendarAccess()
                }
        }
    }
    
    /// Проверяем доступ к календарю при запуске
    private func checkInitialCalendarAccess() {
        Task {
            let status = await calendarService.getAuthorizationStatus()
            DispatchQueue.main.async {
                self.accessGranted = status
            }
        }
    }
}

#Preview {
    RootView()
}
