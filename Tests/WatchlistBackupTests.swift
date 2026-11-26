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
            for: LibraryEntry.self, EpisodeProgress.self, EpisodeWatchEvent.self, MovieWatchEvent.self,
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
        let movieEvent = MovieWatchEvent(tmdbID: 550, title: "Fight Club", watchedAt: Date(timeIntervalSince1970: 1_700_000_000))
        context.insert(movieEvent)
        context.insert(CustomList(name: "Favoriter"))
        try context.save()

        let backup = try WatchlistBackupService.makeBackup(from: context)
        let restored = try WatchlistBackupService.decode(WatchlistBackupService.encode(backup))

        XCTAssertEqual(restored.library.count, 1)
        XCTAssertEqual(restored.customLists.map(\.name), ["Favoriter"])
        XCTAssertTrue(restored.episodeProgress.isEmpty)
        XCTAssertTrue(restored.episodeHistory.isEmpty)
        XCTAssertEqual(restored.movieHistory?.count, 1)
        XCTAssertEqual(restored.movieHistory?.first?.id, movieEvent.id)
        XCTAssertTrue(restored.customListItems.isEmpty)
        XCTAssertTrue(restored.premiereReminders.isEmpty)
    }

    func testOlderSchemaV1BackupWithoutMovieHistoryStillDecodes() throws {
        let json = """
        {
          "schemaVersion": 1,
          "exportedAt": "2026-11-25T00:00:00Z",
          "library": [],
          "episodeProgress": [],
          "episodeHistory": [],
          "customLists": [],
          "customListItems": [],
          "premiereReminders": []
        }
        """.data(using: .utf8)!

        let backup = try WatchlistBackupService.decode(json)
        XCTAssertEqual(backup.schemaVersion, 1)
        XCTAssertTrue((backup.movieHistory ?? []).isEmpty)
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

    func testRejectsLibraryStableIDThatDoesNotMatchTMDBIdentity() throws {
        let item = MediaItem(
            id: 550, kind: .movie, title: "Fight Club", overview: "",
            posterPath: nil, backdropPath: nil, releaseDate: nil, voteAverage: 0
        )
        let backup = WatchlistBackup(
            library: [LibraryRecord(LibraryEntry(item: item))],
            episodeProgress: [], episodeHistory: [], customLists: [],
            customListItems: [], premiereReminders: []
        )
        let validJSON = String(decoding: try WatchlistBackupService.encode(backup), as: UTF8.self)
        let invalidJSON = validJSON.replacingOccurrences(
            of: "movie-550",
            with: "movie-551"
        )

        XCTAssertNotEqual(validJSON, invalidJSON)
        XCTAssertThrowsError(try WatchlistBackupService.decode(Data(invalidJSON.utf8)))
    }

    func testRejectsPersonalRatingOutsideOneToTen() throws {
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
        entry.personalRating = 11
        let backup = WatchlistBackup(
            library: [LibraryRecord(entry)],
            episodeProgress: [],
            episodeHistory: [],
            customLists: [],
            customListItems: [],
            premiereReminders: []
        )

        XCTAssertThrowsError(try WatchlistBackupService.encode(backup))
    }

    func testRejectsCustomListMembershipWithMismatchedStableIdentity() throws {
        let list = CustomList(id: "list-1", name: "Favoriter",
            createdAt: .now, updatedAt: .now)
        let movie = MediaItem(
            id: 550, kind: .movie, title: "Fight Club", overview: "",
            posterPath: nil, backdropPath: nil, releaseDate: nil, voteAverage: 0
        )
        let membership = CustomListItem(listID: list.id, item: movie)
        let backup = WatchlistBackup(
            library: [],
            episodeProgress: [],
            episodeHistory: [],
            customLists: [CustomListRecord(list)],
            customListItems: [CustomListItemRecord(membership)],
            premiereReminders: []
        )
        let validJSON = String(decoding: try WatchlistBackupService.encode(backup), as: UTF8.self)
        let invalidJSON = validJSON.replacingOccurrences(
            of: "list-1::movie-550",
            with: "list-1::movie-551"
        )

        XCTAssertNotEqual(validJSON, invalidJSON)
        XCTAssertThrowsError(try WatchlistBackupService.decode(Data(invalidJSON.utf8)))
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
        let backup = WatchlistBackup(
            library: [LibraryRecord(LibraryEntry(item: item))],
            episodeProgress: [],
            episodeHistory: [],
            customLists: [],
            customListItems: [],
            premiereReminders: []
        )
        let validJSON = String(decoding: try WatchlistBackupService.encode(backup), as: UTF8.self)
        let invalidJSON = validJSON.replacingOccurrences(of: "\"mediaKind\" : \"movie\"", with: "\"mediaKind\" : \"unknown-kind\"")
        XCTAssertNotEqual(validJSON, invalidJSON)
        XCTAssertThrowsError(try WatchlistBackupService.decode(Data(invalidJSON.utf8)))
    }
}
