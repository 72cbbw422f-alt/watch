import XCTest
import SwiftData
@testable import WATCHLIST

@MainActor
final class WatchlistImportTests: XCTestCase {
    private func item(id: Int, title: String) -> MediaItem {
        MediaItem(
            id: id,
            kind: .movie,
            title: title,
            overview: "Imported description",
            posterPath: nil,
            backdropPath: nil,
            releaseDate: "2020-01-01",
            voteAverage: 7.5
        )
    }

    func testPreviewCountsNewAndMatchingLibraryRecords() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: LibraryEntry.self, EpisodeProgress.self,
            EpisodeWatchEvent.self, CustomList.self, CustomListItem.self, PremiereReminder.self,
            configurations: configuration)
        let context = ModelContext(container)
        let existing = LibraryEntry(item: item(id: 1, title: "Existing"))
        context.insert(existing)
        try context.save()

        let incomingExisting = LibraryEntry(item: item(id: 1, title: "Backup title"))
        let incomingNew = LibraryEntry(item: item(id: 2, title: "New title"))
        let backup = WatchlistBackup(
            library: [LibraryRecord(incomingExisting), LibraryRecord(incomingNew)],
            episodeProgress: [], episodeHistory: [], customLists: [],
            customListItems: [], premiereReminders: []
        )

        let preview = try WatchlistImportService.preview(backup, in: context)

        XCTAssertEqual(preview.newLibraryItems, 1)
        XCTAssertEqual(preview.updatedLibraryItems, 1)
    }

    func testMergeAddsNewItemsWithoutOverwritingExistingItems() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: LibraryEntry.self, EpisodeProgress.self,
            EpisodeWatchEvent.self, CustomList.self, CustomListItem.self, PremiereReminder.self,
            configurations: configuration)
        let context = ModelContext(container)
        let existing = LibraryEntry(item: item(id: 1, title: "My original title"))
        existing.personalNotes = "Keep my notes"
        context.insert(existing)
        try context.save()

        let incomingExisting = LibraryEntry(item: item(id: 1, title: "Backup replacement"))
        incomingExisting.personalNotes = "Backup notes"
        let incomingNew = LibraryEntry(item: item(id: 2, title: "New title"))
        let backup = WatchlistBackup(
            library: [LibraryRecord(incomingExisting), LibraryRecord(incomingNew)],
            episodeProgress: [], episodeHistory: [], customLists: [],
            customListItems: [], premiereReminders: []
        )

        let summary = try WatchlistImportService.merge(backup, into: context)
        let saved = try context.fetch(FetchDescriptor<LibraryEntry>())

        XCTAssertEqual(summary.newLibraryItems, 1)
        XCTAssertEqual(saved.count, 2)
        XCTAssertEqual(saved.first(where: { $0.stableID == "movie-1" })?.title, "My original title")
        XCTAssertEqual(saved.first(where: { $0.stableID == "movie-1" })?.personalNotes, "Keep my notes")
        XCTAssertNotNil(saved.first(where: { $0.stableID == "movie-2" }))
    }
}
