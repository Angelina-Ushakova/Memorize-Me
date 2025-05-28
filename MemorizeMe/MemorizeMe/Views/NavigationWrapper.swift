import SwiftUI

struct NavigationWrapper<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        NavigationView {
            content
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct SettingsViewWithNavigation: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Binding var accessGranted: Bool

    var body: some View {
        NavigationView {
            SettingsView(viewModel: viewModel, accessGranted: $accessGranted)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
