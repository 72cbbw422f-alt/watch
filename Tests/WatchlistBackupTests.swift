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

    func testRejectsInvalidLibraryIdentity() {
        let record = LibraryRecord(
            stableID: "",
            tmdbID: 550,
            mediaKind: "movie",
            title: "Fight Club",
            overview: "",
            posterPath: nil,
            backdropPath: nil,
            releaseDate: nil,
            voteAverage: 0,
            statusRawValue: "watched",
            dateAdded: .now,
            dateUpdated: .now,
            isFavorite: false,
            personalRating: nil,
            personalNotes: "",
            episodeTotalCount: nil,
            nextEpisodeTitle: nil,
            nextEpisodeCode: nil,
            nextEpisodeAirDate: nil
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

private extension LibraryRecord {
    init(
        stableID: String,
        tmdbID: Int,
        mediaKind: String,
        title: String,
        overview: String,
        posterPath: String?,
        backdropPath: String?,
        releaseDate: String?,
        voteAverage: Double,
        statusRawValue: String,
        dateAdded: Date,
        dateUpdated: Date,
        isFavorite: Bool,
        personalRating: Int?,
        personalNotes: String,
        episodeTotalCount: Int?,
        nextEpisodeTitle: String?,
        nextEpisodeCode: String?,
        nextEpisodeAirDate: String?
    ) {
        self.stableID = stableID
        self.tmdbID = tmdbID
        self.mediaKind = mediaKind
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
        self.statusRawValue = statusRawValue
        self.dateAdded = dateAdded
        self.dateUpdated = dateUpdated
        self.isFavorite = isFavorite
        self.personalRating = personalRating
        self.personalNotes = personalNotes
        self.episodeTotalCount = episodeTotalCount
        self.nextEpisodeTitle = nextEpisodeTitle
        self.nextEpisodeCode = nextEpisodeCode
        self.nextEpisodeAirDate = nextEpisodeAirDate
    }
}
