import Foundation
import UserNotifications

enum PremiereNotificationError: LocalizedError {
    case reminderTooLate
    case permissionDenied
    case invalidLeadDays

    var errorDescription: String? {
        switch self {
        case .reminderTooLate:
            "Påminnelsedatumet har redan passerat. Välj ett senare premiärdatum."
        case .permissionDenied:
            "Notiser är avstängda för WATCHLIST. Aktivera dem i iPhone-inställningarna."
        case .invalidLeadDays:
            "Påminnelsen har ett ogiltigt antal dagar före premiären."
        }
    }
}

/// Pure date calculation shared by notification scheduling and unit tests.
enum PremiereNotificationSchedule {
    static func scheduledDate(
        premiereDate: Date,
        leadDays: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) throws -> Date {
        guard [0, 1, 7].contains(leadDays) else {
            throw PremiereNotificationError.invalidLeadDays
        }

        let reminderDate = calendar.date(
            byAdding: .day,
            value: -leadDays,
            to: premiereDate
        ) ?? premiereDate
        let scheduledDate = calendar.date(
            bySettingHour: 9,
            minute: 0,
            second: 0,
            of: reminderDate
        ) ?? reminderDate

        guard scheduledDate > now else {
            throw PremiereNotificationError.reminderTooLate
        }
        return scheduledDate
    }

    static func dateComponents(for scheduledDate: Date, calendar: Calendar = .current) -> DateComponents {
        calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledDate)
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
        let scheduledDate = try PremiereNotificationSchedule.scheduledDate(
            premiereDate: reminder.premiereDate,
            leadDays: reminder.leadDays
        )
        let components = PremiereNotificationSchedule.dateComponents(for: scheduledDate)

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
