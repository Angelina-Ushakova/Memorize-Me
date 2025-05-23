import Foundation
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case light, dark
    var id: String { rawValue }
    var title: String {
        switch self {
        case .light: return "Светлая"
        case .dark: return "Тёмная"
        }
    }
}

final class SettingsViewModel: ObservableObject {
    @Published var isCalendarAccessGranted: Bool
    @Published var followSystemTheme: Bool = false {
        didSet {
            applyCurrentTheme()
            saveSettings()
        }
    }
    @Published var selectedTheme: AppTheme = .light {
        didSet {
            if !followSystemTheme {
                applyTheme(selectedTheme)
                saveSettings()
            }
        }
    }
    
    private let calendarService = CalendarSyncService()
    private let followKey = "followSystemTheme"
    private let themeKey = "selectedTheme"
    
    init(isCalendarAccessGranted: Bool) {
        self.isCalendarAccessGranted = isCalendarAccessGranted
        loadSettings()
    }

    private func loadSettings() {
        if UserDefaults.standard.object(forKey: followKey) != nil {
            self.followSystemTheme = UserDefaults.standard.bool(forKey: followKey)
        }
        if let themeRaw = UserDefaults.standard.string(forKey: themeKey),
           let theme = AppTheme(rawValue: themeRaw) {
            self.selectedTheme = theme
        }
        applyCurrentTheme()
    }

    private func saveSettings() {
        UserDefaults.standard.set(selectedTheme.rawValue, forKey: themeKey)
        UserDefaults.standard.set(followSystemTheme, forKey: followKey)
    }

    private func applyCurrentTheme() {
        if followSystemTheme {
            setSystemTheme()
        } else {
            applyTheme(selectedTheme)
        }
    }

    func applyTheme(_ theme: AppTheme) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        let style: UIUserInterfaceStyle = (theme == .dark) ? .dark : .light
        for window in windowScene.windows {
            window.overrideUserInterfaceStyle = style
        }
    }
    
    func setSystemTheme() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        for window in windowScene.windows {
            window.overrideUserInterfaceStyle = .unspecified
        }
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    func resetAllData() {
        print("Сброс всех данных произведен")
    }
    
    func checkCalendarAccess() async {
        if let status = await calendarService.getAuthorizationStatus() {
            DispatchQueue.main.async {
                self.isCalendarAccessGranted = status
            }
        }
    }
}
