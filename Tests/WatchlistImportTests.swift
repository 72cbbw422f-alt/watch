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

    func testReminderSchedulingSelectionIncludesOnlyNewReminderIDs() {
        let existingReminder = PremiereReminder(
            stableID: "movie-550", tmdbID: 550, mediaKind: MediaKind.movie.rawValue,
            title: "Fight Club", premiereDate: Date(timeIntervalSince1970: 1_900_000_000),
            leadDays: 1, notificationID: "premiere-movie-550", dateCreated: .now
        )
        let newReminder = PremiereReminder(
            stableID: "tv-1396", tmdbID: 1396, mediaKind: MediaKind.television.rawValue,
            title: "Breaking Bad", premiereDate: Date(timeIntervalSince1970: 1_900_000_000),
            leadDays: 7, notificationID: "premiere-tv-1396", dateCreated: .now
        )
        let backup = WatchlistBackup(
            library: [], episodeProgress: [], episodeHistory: [], customLists: [],
            customListItems: [],
            premiereReminders: [PremiereReminderRecord(existingReminder), PremiereReminderRecord(newReminder)]
        )

        let ids = WatchlistImportService.reminderIDsToSchedule(
            from: backup,
            existingReminderIDs: [existingReminder.stableID]
        )

        XCTAssertEqual(ids, Set([newReminder.stableID]))
    }

    func testRepeatedImportSchedulesNoExistingReminderIDs() {
        let reminder = PremiereReminder(
            stableID: "movie-550", tmdbID: 550, mediaKind: MediaKind.movie.rawValue,
            title: "Fight Club", premiereDate: Date(timeIntervalSince1970: 1_900_000_000),
            leadDays: 1, notificationID: "premiere-movie-550", dateCreated: .now
        )
        let backup = WatchlistBackup(
            library: [], episodeProgress: [], episodeHistory: [], customLists: [],
            customListItems: [],
            premiereReminders: [PremiereReminderRecord(reminder)]
        )

        let ids = WatchlistImportService.reminderIDsToSchedule(
            from: backup,
            existingReminderIDs: [reminder.stableID]
        )

        XCTAssertTrue(ids.isEmpty)
    }

    func testPreviewCountsNewAndMatchingLibraryRecords() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: LibraryEntry.self, EpisodeProgress.self,
            EpisodeWatchEvent.self, MovieWatchEvent.self, CustomList.self, CustomListItem.self, PremiereReminder.self,
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
        XCTAssertEqual(preview.matchingLibraryItems, 1)
        XCTAssertEqual(preview.localOnlyLibraryItems, 0)
    }

    func testMergeAddsNewItemsWithoutOverwritingExistingItems() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: LibraryEntry.self, EpisodeProgress.self,
            EpisodeWatchEvent.self, MovieWatchEvent.self, CustomList.self, CustomListItem.self, PremiereReminder.self,
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

    func testPreviewCountsLocalOnlyItemsAndMergePreservesThem() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: LibraryEntry.self, EpisodeProgress.self,
            EpisodeWatchEvent.self, MovieWatchEvent.self, CustomList.self, CustomListItem.self, PremiereReminder.self,
            configurations: configuration)
        let context = ModelContext(container)
        context.insert(LibraryEntry(item: item(id: 10, title: "Only on this device")))
        try context.save()

        let backup = WatchlistBackup(
            library: [LibraryRecord(LibraryEntry(item: item(id: 11, title: "From backup")))],
            episodeProgress: [], episodeHistory: [], customLists: [],
            customListItems: [], premiereReminders: []
        )

        let preview = try WatchlistImportService.preview(backup, in: context)
        XCTAssertEqual(preview.localOnlyLibraryItems, 1)

        _ = try WatchlistImportService.merge(backup, into: context)
        let saved = try context.fetch(FetchDescriptor<LibraryEntry>())
        XCTAssertEqual(saved.count, 2)
        XCTAssertNotNil(saved.first(where: { $0.stableID == "movie-10" }))
        XCTAssertNotNil(saved.first(where: { $0.stableID == "movie-11" }))
    }

    func testInvalidBackupIsRejectedBeforeAnyRecordsAreInserted() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: LibraryEntry.self, EpisodeProgress.self,
            EpisodeWatchEvent.self, MovieWatchEvent.self, CustomList.self, CustomListItem.self, PremiereReminder.self,
            configurations: configuration)
        let context = ModelContext(container)

        let list = CustomList(id: "list-invalid", name: "Favoriter",
            createdAt: .now, updatedAt: .now)
        let movie = item(id: 550, title: "Fight Club")
        let membership = CustomListItem(listID: list.id, item: movie)
        let backup = WatchlistBackup(
            library: [LibraryRecord(LibraryEntry(item: item(id: 99, title: "Should not import")))],
            episodeProgress: [],
            episodeHistory: [],
            customLists: [CustomListRecord(list)],
            customListItems: [CustomListItemRecord(membership)],
            premiereReminders: []
        )
        let validJSON = String(decoding: try WatchlistBackupService.encode(backup), as: UTF8.self)
        let tamperedJSON = validJSON.replacingOccurrences(
            of: "list-invalid::movie-550",
            with: "list-invalid::movie-551"
        )
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let tamperedBackup = try decoder.decode(WatchlistBackup.self, from: Data(tamperedJSON.utf8))

        XCTAssertThrowsError(try WatchlistImportService.merge(tamperedBackup, into: context))
        XCTAssertTrue(try context.fetch(FetchDescriptor<LibraryEntry>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<CustomList>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<CustomListItem>()).isEmpty)
    }

    func testRepeatedImportIsIdempotent() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: LibraryEntry.self, EpisodeProgress.self,
            EpisodeWatchEvent.self, MovieWatchEvent.self, CustomList.self, CustomListItem.self, PremiereReminder.self,
            configurations: configuration)
        let context = ModelContext(container)
        let viewedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let movieEvent = MovieWatchEvent(
            tmdbID: 22,
            title: "Once",
            watchedAt: viewedAt
        )
        let episode = TVEpisode(
            id: 101,
            name: "Pilot",
            overview: "",
            episodeNumber: 1,
            seasonNumber: 1,
            airDate: "2026-01-10",
            runtime: 45,
            stillPath: nil,
            voteAverage: 8
        )
        let episodeProgress = EpisodeProgress(seriesID: 1396, episode: episode, isWatched: true)
        let episodeEvent = EpisodeWatchEvent(
            id: UUID(),
            seriesID: 1396,
            episodeID: 101,
            seasonNumber: 1,
            episodeNumber: 1,
            episodeTitle: "Pilot",
            watchedAt: viewedAt,
            source: "manual"
        )
        let backup = WatchlistBackup(
            library: [LibraryRecord(LibraryEntry(item: item(id: 22, title: "Once")))],
            episodeProgress: [EpisodeProgressRecord(episodeProgress)],
            episodeHistory: [EpisodeHistoryRecord(episodeEvent)],
            movieHistory: [MovieHistoryRecord(movieEvent)],
            customLists: [], customListItems: [], premiereReminders: []
        )

        let first = try WatchlistImportService.merge(backup, into: context)
        let second = try WatchlistImportService.merge(backup, into: context)
        let saved = try context.fetch(FetchDescriptor<LibraryEntry>())
        let savedProgress = try context.fetch(FetchDescriptor<EpisodeProgress>())
        let savedEpisodeEvents = try context.fetch(FetchDescriptor<EpisodeWatchEvent>())
        let savedMovieEvents = try context.fetch(FetchDescriptor<MovieWatchEvent>())

        XCTAssertEqual(first.newLibraryItems, 1)
        XCTAssertEqual(first.newEpisodeStates, 1)
        XCTAssertEqual(first.newHistoryEvents, 1)
        XCTAssertEqual(first.newMovieHistoryEvents, 1)
        XCTAssertEqual(second.newLibraryItems, 0)
        XCTAssertEqual(second.newEpisodeStates, 0)
        XCTAssertEqual(second.newHistoryEvents, 0)
        XCTAssertEqual(second.newMovieHistoryEvents, 0)
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(savedProgress.count, 1)
        XCTAssertEqual(savedProgress.first?.stableID, episodeProgress.stableID)
        XCTAssertEqual(savedEpisodeEvents.count, 1)
        XCTAssertEqual(savedEpisodeEvents.first?.id, episodeEvent.id)
        XCTAssertEqual(savedMovieEvents.count, 1)
        XCTAssertEqual(savedMovieEvents.first?.id, movieEvent.id)
    }

    func testMergeRestoresEpisodeProgressHistoryListsAndReminders() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: LibraryEntry.self, EpisodeProgress.self,
            EpisodeWatchEvent.self, MovieWatchEvent.self, CustomList.self, CustomListItem.self, PremiereReminder.self,
            configurations: configuration)
        let context = ModelContext(container)

        let episode = TVEpisode(
            id: 101,
            name: "Pilot",
            overview: "First episode",
            episodeNumber: 1,
            seasonNumber: 1,
            airDate: "2026-01-10",
            runtime: 45,
            stillPath: nil,
            voteAverage: 8
        )
        let progress = EpisodeProgress(seriesID: 1396, episode: episode, isWatched: true)
        let viewedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let event = EpisodeWatchEvent(
            id: UUID(),
            seriesID: 1396,
            episodeID: 101,
            seasonNumber: 1,
            episodeNumber: 1,
            episodeTitle: "Pilot",
            watchedAt: viewedAt,
            source: "manual"
        )
        let movieEvent = MovieWatchEvent(tmdbID: 550, title: "Fight Club", watchedAt: viewedAt)
        let list = CustomList(id: "list-favorites", name: "Favoriter",
            createdAt: viewedAt, updatedAt: viewedAt)
        let movie = item(id: 550, title: "Fight Club")
        let membership = CustomListItem(listID: list.id, item: movie)
        let reminder = PremiereReminder(
            stableID: "movie-550",
            tmdbID: 550,
            mediaKind: MediaKind.movie.rawValue,
            title: "Fight Club",
            premiereDate: Date(timeIntervalSince1970: 1_800_000_000),
            leadDays: 1,
            notificationID: "premiere-movie-550",
            dateCreated: viewedAt
        )
        let backup = WatchlistBackup(
            library: [],
            episodeProgress: [EpisodeProgressRecord(progress)],
            episodeHistory: [EpisodeHistoryRecord(event)],
            movieHistory: [MovieHistoryRecord(movieEvent)],
            customLists: [CustomListRecord(list)],
            customListItems: [CustomListItemRecord(membership)],
            premiereReminders: [PremiereReminderRecord(reminder)]
        )

        let summary = try WatchlistImportService.merge(backup, into: context)

        XCTAssertEqual(summary.newEpisodeStates, 1)
        XCTAssertEqual(summary.newHistoryEvents, 1)
        XCTAssertEqual(summary.newMovieHistoryEvents, 1)
        XCTAssertEqual(summary.newCustomLists, 1)
        XCTAssertEqual(summary.newCustomListItems, 1)
        XCTAssertEqual(summary.newReminders, 1)

        let restoredProgress = try context.fetch(FetchDescriptor<EpisodeProgress>())
        let restoredHistory = try context.fetch(FetchDescriptor<EpisodeWatchEvent>())
        let restoredMovieHistory = try context.fetch(FetchDescriptor<MovieWatchEvent>())
        let restoredLists = try context.fetch(FetchDescriptor<CustomList>())
        let restoredItems = try context.fetch(FetchDescriptor<CustomListItem>())
        let restoredReminders = try context.fetch(FetchDescriptor<PremiereReminder>())

        XCTAssertEqual(restoredProgress.first?.stableID, progress.stableID)
        XCTAssertTrue(restoredProgress.first?.isWatched == true)
        XCTAssertEqual(restoredHistory.first?.id, event.id)
        XCTAssertEqual(restoredHistory.first?.watchedAt, viewedAt)
        XCTAssertEqual(restoredMovieHistory.first?.tmdbID, 550)
        XCTAssertEqual(restoredMovieHistory.first?.watchedAt, viewedAt)
        XCTAssertEqual(restoredLists.first?.id, list.id)
        XCTAssertEqual(restoredItems.first?.stableID, membership.stableID)
        XCTAssertEqual(restoredReminders.first?.stableID, reminder.stableID)
        XCTAssertEqual(restoredReminders.first?.notificationID, reminder.notificationID)
    }
}
