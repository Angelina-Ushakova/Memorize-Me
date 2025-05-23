import SwiftUI
import EventKit

struct RootView: View {
    @StateObject private var viewModel = RootViewModel()

    var body: some View {
        // В зависимости от статуса доступа к календарю показываем разные экраны
        if let accessGranted = viewModel.calendarAccessStatus {
            if accessGranted {
                MainTabView(accessGranted: $viewModel.calendarAccessStatus)
            } else {
                AccessDeniedView()
            }
        } else {
            RequestCalendarAccessView(accessGranted: $viewModel.calendarAccessStatus)
                .onAppear {
                    // При появлении экрана проверяем текущий статус доступа
                    viewModel.checkCalendarAccess()
                }
        }
    }
}

#Preview {
    RootView()
}
