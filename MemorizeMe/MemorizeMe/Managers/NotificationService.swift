import Foundation
import UserNotifications

final class NotificationService {
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            return granted
        } catch {
            print("Ошибка запроса разрешения на уведомления: \(error)")
            return false
        }
    }
    
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    func scheduleNotifications(for specialDates: [SignificantDate]) async {
        await cancelAllNotifications()
        
        let status = await checkPermissionStatus()
        guard status == .authorized else {
            print("Нет разрешения на уведомления")
            return
        }
        
        var scheduledCount = 0
        
        for special in specialDates {
            guard special.notificationDate > Date() else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = special.title
            content.body = createNotificationBody(for: special)
            content.sound = .default
            content.badge = 1
            
            let dateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: special.notificationDate
            )
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: special.id.uuidString,
                content: content,
                trigger: trigger
            )
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                scheduledCount += 1
            } catch {
                print("Ошибка планирования уведомления: \(error)")
            }
        }
        
        print("Всего запланировано уведомлений: \(scheduledCount)")
    }
    
    func cancelNotification(id: String) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    func cancelAllNotifications() async {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func getPendingNotificationsCount() async -> Int {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return requests.count
    }
    
    private func createNotificationBody(for special: SignificantDate) -> String {
        switch special.type {
        case .action:
            return "Не забудьте выполнить запланированное действие"
        case .greeting:
            return "Время поздравить с важным событием!"
        case .anniversary:
            return "Особенная годовщина"
        case .prettyDate:
            return "Сегодня особенная дата!"
        case .throwback:
            return "Вспомните это приятное событие из прошлого"
        case .other:
            return "Напоминание о событии"
        }
    }
}
