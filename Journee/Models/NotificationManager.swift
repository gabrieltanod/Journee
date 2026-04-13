import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let notificationID = "journee.daily.reminder"

    private init() {}

    // MARK: - Authorization

    func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("Notification auth error: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    // MARK: - Scheduling

    /// Schedule a daily notification at the given hour and minute.
    func scheduleDailyReminder(hour: Int, minute: Int) {
        // Cancel any existing reminder first
        cancelReminder()

        let content = UNMutableNotificationContent()
        content.title = "Journee"
        content.body = "Time to log today's receipts! Keep your budget on track. 💰"
        content.sound = .default
        // Attach a category so tapping opens to Quick Add
        content.categoryIdentifier = "DAILY_REMINDER"
        content.userInfo = ["openQuickAdd": true]

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)

        center.add(request) { error in
            if let error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }

    /// Cancel the daily reminder.
    func cancelReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])
    }

    /// Check if a reminder is currently scheduled.
    func isReminderScheduled(completion: @escaping (Bool) -> Void) {
        center.getPendingNotificationRequests { requests in
            let exists = requests.contains { $0.identifier == self.notificationID }
            DispatchQueue.main.async {
                completion(exists)
            }
        }
    }
}
