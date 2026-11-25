import Foundation
import UserNotifications

enum PremiereNotificationError: LocalizedError {
    case reminderTooLate
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .reminderTooLate:
            "Påminnelsedatumet har redan passerat. Välj ett senare premiärdatum."
        case .permissionDenied:
            "Notiser är avstängda för WATCHLIST. Aktivera dem i iPhone-inställningarna."
        }
    }
}

enum PremiereNotificationService {
    static func schedule(_ reminder: PremiereReminder) async throws {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let authorized: Bool

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            authorized = true
        case .notDetermined:
            authorized = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        case .denied:
            authorized = false
        @unknown default:
            authorized = false
        }

        guard authorized else { throw PremiereNotificationError.permissionDenied }
        try await addNotification(for: reminder, using: center)
    }

    /// Restores an imported reminder only when notification permission already exists.
    /// Import never triggers a permission prompt.
    static func scheduleIfAuthorized(_ reminder: PremiereReminder) async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            try await addNotification(for: reminder, using: center)
            return true
        case .notDetermined, .denied:
            return false
        @unknown default:
            return false
        }
    }

    private static func addNotification(
        for reminder: PremiereReminder,
        using center: UNUserNotificationCenter
    ) async throws {
        let reminderDate = Calendar.current.date(
            byAdding: .day,
            value: -reminder.leadDays,
            to: reminder.premiereDate
        ) ?? reminder.premiereDate
        let scheduledDate = Calendar.current.date(
            bySettingHour: 9,
            minute: 0,
            second: 0,
            of: reminderDate
        ) ?? reminderDate
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: scheduledDate
        )
        guard scheduledDate > .now else {
            throw PremiereNotificationError.reminderTooLate
        }

        let content = UNMutableNotificationContent()
        content.title = "Kommande premiär"
        content.body = "\(reminder.title) har premiär \(reminder.premiereDate.formatted(date: .abbreviated, time: .omitted))."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: reminder.notificationID,
            content: content,
            trigger: trigger
        )
        try await center.add(request)
    }

    static func cancel(_ reminder: PremiereReminder) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [reminder.notificationID]
        )
    }
}
