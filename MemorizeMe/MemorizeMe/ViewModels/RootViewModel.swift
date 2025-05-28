import Foundation
import SwiftUI
import EventKit

/// Отвечает за проверку и запрос доступа к календарю.
@MainActor
final class RootViewModel: ObservableObject {
    @Published var calendarAccessStatus: Bool?
    private let calendarService = CalendarSyncService()
    
    init() {
        
    }
    
    /// Запрашивает у пользователя разрешение на доступ к календарю.
    func requestCalendarAccess() {
        calendarService.requestAccess { [weak self] granted in
            self?.calendarAccessStatus = granted
        }
    }
    
    /// Асинхронно проверяет текущий статус доступа к календарю
    func checkCalendarAccess() {
        Task {
            let status = await calendarService.getAuthorizationStatus()
            // Обновляем UI на главной очереди
            DispatchQueue.main.async {
                self.calendarAccessStatus = status
            }
        }
    }
}

