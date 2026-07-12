import Foundation
import UserNotifications

/// Schedules local reminders for to-dos with due dates. Thin wrapper over
/// `UNUserNotificationCenter` so views don't touch the framework directly.
final class NotificationService {
    private let center = UNUserNotificationCenter.current()
    private(set) var isAuthorized = false

    /// Refresh the cached authorization flag from the system settings.
    func refreshAuthorization() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
    }

    /// Ask the user to allow notifications. Returns whether it was granted.
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            return granted
        } catch {
            return false
        }
    }

    /// Schedule (or replace) a reminder. No-ops for past dates or when off.
    func scheduleReminder(id: String, title: String, date: Date) {
        cancelReminder(id: id)
        guard isAuthorized, date > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "LifeTracker reminder"
        content.body = title
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    func cancelReminder(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    /// Reconcile a to-do's reminder with its current state (called on
    /// create/complete/reopen).
    func sync(_ todo: TodoItem) {
        if let due = todo.dueDate, !todo.isCompleted {
            scheduleReminder(id: todo.reminderIdentifier, title: todo.title, date: due)
        } else {
            cancelReminder(id: todo.reminderIdentifier)
        }
    }
}
