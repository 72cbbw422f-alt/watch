import XCTest
import SwiftData
@testable import WATCHLIST

final class WatchlistBackupTests: XCTestCase {
    func testJSONRoundTripPreservesPersonalLibraryData() throws {
        let item = MediaItem(
            id: 550,
            kind: .movie,
            title: "Fight Club",
            overview: "A test description",
            posterPath: "/poster.jpg",
            backdropPath: "/backdrop.jpg",
            releaseDate: "1999-10-15",
            voteAverage: 8.4
        )
        let entry = LibraryEntry(item: item, status: .watched)
        entry.isFavorite = true
        entry.personalRating = 9
        entry.personalNotes = "Se igen."
        let backup = WatchlistBackup(
            exportedAt: Date(timeIntervalSince1970: 1_700_000_000),
            library: [LibraryRecord(entry)],
            episodeProgress: [],
            episodeHistory: [],
            customLists: [],
            customListItems: [],
            premiereReminders: []
        )

        let data = try WatchlistBackupService.encode(backup)
        let decoded = try WatchlistBackupService.decode(data)

        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.library.count, 1)
        XCTAssertEqual(decoded.library.first?.stableID, "movie-550")
        XCTAssertEqual(decoded.library.first?.statusRawValue, LibraryStatus.watched.rawValue)
        XCTAssertEqual(decoded.library.first?.personalRating, 9)
        XCTAssertEqual(decoded.library.first?.personalNotes, "Se igen.")
        XCTAssertEqual(decoded.library.first?.isFavorite, true)
    }

    func testBackupServiceExportsAllLocalCollections() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: LibraryEntry.self, EpisodeProgress.self, EpisodeWatchEvent.self,
            CustomList.self, CustomListItem.self, PremiereReminder.self,
            configurations: configuration
        )
        let context = ModelContext(container)
        let item = MediaItem(
            id: 550,
            kind: .movie,
            title: "Fight Club",
            overview: "A test description",
            posterPath: nil,
            backdropPath: nil,
            releaseDate: "1999-10-15",
            voteAverage: 8.4
        )
        context.insert(LibraryEntry(item: item))
        context.insert(CustomList(name: "Favoriter"))
        try context.save()

        let backup = try WatchlistBackupService.makeBackup(from: context)
        let restored = try WatchlistBackupService.decode(WatchlistBackupService.encode(backup))

        XCTAssertEqual(restored.library.count, 1)
        XCTAssertEqual(restored.customLists.map(\.name), ["Favoriter"])
        XCTAssertTrue(restored.episodeProgress.isEmpty)
        XCTAssertTrue(restored.episodeHistory.isEmpty)
        XCTAssertTrue(restored.customListItems.isEmpty)
        XCTAssertTrue(restored.premiereReminders.isEmpty)
    }

    func testRejectsInvalidLibraryIdentity() throws {
        let json = """
        {
          "schemaVersion": 1,
          "exportedAt": "2026-11-25T00:00:00Z",
          "library": [{
            "stableID": "",
            "tmdbID": 550,
            "mediaKind": "movie",
            "title": "Fight Club",
            "overview": "",
            "posterPath": null,
            "backdropPath": null,
            "releaseDate": null,
            "voteAverage": 0,
            "statusRawValue": "watched",
            "dateAdded": "2026-11-25T00:00:00Z",
            "dateUpdated": "2026-11-25T00:00:00Z",
            "isFavorite": false,
            "personalRating": null,
            "personalNotes": "",
            "episodeTotalCount": null,
            "nextEpisodeTitle": null,
            "nextEpisodeCode": null,
            "nextEpisodeAirDate": null
          }],
          "episodeProgress": [],
          "episodeHistory": [],
          "customLists": [],
          "customListItems": [],
          "premiereReminders": []
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try WatchlistBackupService.decode(json))
    }

    func testRejectsUnknownMediaKindAndStatus() throws {
        let item = MediaItem(
            id: 550,
            kind: .movie,
            title: "Fight Club",
            overview: "",
            posterPath: nil,
            backdropPath: nil,
            releaseDate: nil,
            voteAverage: 0
        )
        let entry = LibraryEntry(item: item)
        var record = LibraryRecord(entry)
        record = LibraryRecord(
            stableID: record.stableID,
            tmdbID: record.tmdbID,
            mediaKind: "unknown-kind",
            title: record.title,
            overview: record.overview,
            posterPath: record.posterPath,
            backdropPath: record.backdropPath,
            releaseDate: record.releaseDate,
            voteAverage: record.voteAverage,
            statusRawValue: record.statusRawValue,
            dateAdded: record.dateAdded,
            dateUpdated: record.dateUpdated,
            isFavorite: record.isFavorite,
            personalRating: record.personalRating,
            personalNotes: record.personalNotes,
            episodeTotalCount: record.episodeTotalCount,
            nextEpisodeTitle: record.nextEpisodeTitle,
            nextEpisodeCode: record.nextEpisodeCode,
            nextEpisodeAirDate: record.nextEpisodeAirDate
        )
        let backup = WatchlistBackup(
            library: [record],
            episodeProgress: [],
            episodeHistory: [],
            customLists: [],
            customListItems: [],
            premiereReminders: []
        )
        XCTAssertThrowsError(try WatchlistBackupService.encode(backup))
    }
}
