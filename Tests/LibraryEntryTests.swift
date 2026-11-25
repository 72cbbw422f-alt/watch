import XCTest
import SwiftData
@testable import WATCHLIST

final class LibraryEntryTests: XCTestCase {
    private func makeItem(
        id: Int = 550,
        kind: MediaKind = .movie
    ) -> MediaItem {
        MediaItem(
            id: id,
            kind: kind,
            title: kind == .movie ? "Fight Club" : "Breaking Bad",
            overview: "A test description",
            posterPath: "/poster.jpg",
            backdropPath: "/backdrop.jpg",
            releaseDate: "1999-10-15",
            voteAverage: 8.4
        )
    }

    func testNewEntryStartsInWantToWatchAndIsNotFavorite() {
        let entry = LibraryEntry(item: makeItem())

        XCTAssertEqual(entry.stableID, "movie-550")
        XCTAssertEqual(entry.status, .wantToWatch)
        XCTAssertFalse(entry.isFavorite)
        XCTAssertEqual(entry.title, "Fight Club")
        XCTAssertEqual(entry.tmdbID, 550)
    }

    func testStatusMutationUpdatesRawValueAndTimestamp() {
        let entry = LibraryEntry(item: makeItem())
        let oldDate = Date(timeIntervalSince1970: 1)
        entry.dateUpdated = oldDate

        entry.status = .watching

        XCTAssertEqual(entry.statusRawValue, LibraryStatus.watching.rawValue)
        XCTAssertEqual(entry.status, .watching)
        XCTAssertGreaterThan(entry.dateUpdated, oldDate)
    }

    func testUnknownStoredStatusFallsBackToWantToWatch() {
        let entry = LibraryEntry(item: makeItem())
        entry.statusRawValue = "unknown-status"

        XCTAssertEqual(entry.status, .wantToWatch)
    }

    func testMediaItemRoundTripPreservesCatalogueFields() {
        let original = makeItem(id: 1396, kind: .television)
        let entry = LibraryEntry(item: original, status: .watched)

        XCTAssertEqual(entry.mediaItem, original)
        XCTAssertEqual(entry.status, .watched)
    }

    func testEntryCanBeInsertedFetchedAndDeletedInMemory() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LibraryEntry.self,
            configurations: configuration
        )
        let context = ModelContext(container)
        let entry = LibraryEntry(item: makeItem())

        context.insert(entry)
        try context.save()

        let savedEntries = try context.fetch(FetchDescriptor<LibraryEntry>())
        XCTAssertEqual(savedEntries.count, 1)
        XCTAssertEqual(savedEntries.first?.stableID, "movie-550")

        context.delete(entry)
        try context.save()

        let remainingEntries = try context.fetch(FetchDescriptor<LibraryEntry>())
        XCTAssertTrue(remainingEntries.isEmpty)
    }
}
