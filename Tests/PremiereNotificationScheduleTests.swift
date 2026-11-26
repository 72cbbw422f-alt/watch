import XCTest
@testable import WATCHLIST

final class PremiereNotificationScheduleTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(
            year: year, month: month, day: day, hour: hour
        ))!
    }

    func testSameDayReminderIsScheduledAtNineInTheMorning() throws {
        let scheduled = try PremiereNotificationSchedule.scheduledDate(
            premiereDate: date(2026, 12, 20),
            leadDays: 0,
            now: date(2026, 12, 1),
            calendar: calendar
        )

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduled)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 12)
        XCTAssertEqual(components.day, 20)
        XCTAssertEqual(components.hour, 9)
        XCTAssertEqual(components.minute, 0)
    }

    func testOneDayReminderUsesPreviousCalendarDay() throws {
        let scheduled = try PremiereNotificationSchedule.scheduledDate(
            premiereDate: date(2026, 12, 20),
            leadDays: 1,
            now: date(2026, 12, 1),
            calendar: calendar
        )

        let components = calendar.dateComponents([.day, .hour], from: scheduled)
        XCTAssertEqual(components.day, 19)
        XCTAssertEqual(components.hour, 9)
    }

    func testSevenDayReminderUsesPreviousCalendarWeek() throws {
        let scheduled = try PremiereNotificationSchedule.scheduledDate(
            premiereDate: date(2026, 12, 20),
            leadDays: 7,
            now: date(2026, 12, 1),
            calendar: calendar
        )

        let components = calendar.dateComponents([.day, .hour], from: scheduled)
        XCTAssertEqual(components.day, 13)
        XCTAssertEqual(components.hour, 9)
    }

    func testPastReminderDateIsRejected() {
        XCTAssertThrowsError(try PremiereNotificationSchedule.scheduledDate(
            premiereDate: date(2026, 12, 2),
            leadDays: 1,
            now: date(2026, 12, 1, hour: 10),
            calendar: calendar
        )) { error in
            guard let error = error as? PremiereNotificationError else { return XCTFail("Unexpected error: \\(error)") }
            if case .reminderTooLate = error { } else { XCTFail("Expected reminderTooLate, got \\(error)") }
        }
    }

    func testUnsupportedLeadTimeIsRejected() {
        XCTAssertThrowsError(try PremiereNotificationSchedule.scheduledDate(
            premiereDate: date(2026, 12, 20),
            leadDays: 3,
            now: date(2026, 12, 1),
            calendar: calendar
        )) { error in
            guard let error = error as? PremiereNotificationError else { return XCTFail("Unexpected error: \\(error)") }
            if case .invalidLeadDays = error { } else { XCTFail("Expected invalidLeadDays, got \\(error)") }
        }
    }
}
