import XCTest
import SwiftData
@testable import WATCHLIST

final class PremiereReminderTests: XCTestCase {
    private func makeItem() -> MediaItem {
        MediaItem(
            id: 550,
            kind: .movie,
            title: "Fight Club",
            overview: "A test description",
            releaseDate: "2026-12-01"
        )
    }

    func testReminderUsesStableMediaIdentifierAndLeadTime() {
        let premiereDate = Date(timeIntervalSince1970: 1_800_000_000)
        let reminder = PremiereReminder(item: makeItem(), premiereDate: premiereDate, leadDays: 1)

        XCTAssertEqual(reminder.stableID, "movie-550")
        XCTAssertEqual(reminder.notificationID, "premiere-movie-550")
        XCTAssertEqual(reminder.leadDays, 1)
        XCTAssertEqual(reminder.leadDescription, "Dagen före")
        XCTAssertEqual(reminder.premiereDate, premiereDate)
    }

    func testReminderPersistsInMemory() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PremiereReminder.self,
            configurations: configuration
        )
        let context = ModelContext(container)
        let reminder = PremiereReminder(
            item: makeItem(),
            premiereDate: Date(timeIntervalSince1970: 1_800_000_000),
            leadDays: 7
        )

        context.insert(reminder)
        try context.save()

        let saved = try context.fetch(FetchDescriptor<PremiereReminder>())
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.stableID, "movie-550")
        XCTAssertEqual(saved.first?.leadDescription, "En vecka före")
    }
}
