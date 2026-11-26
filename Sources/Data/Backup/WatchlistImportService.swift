import Foundation
import SwiftData

struct WatchlistImportPreview {
    let newLibraryItems: Int
    let matchingLibraryItems: Int
    let localOnlyLibraryItems: Int
    let newEpisodeStates: Int
    let newHistoryEvents: Int
    let newMovieHistoryEvents: Int
    let newCustomLists: Int
    let newCustomListItems: Int
    let newReminders: Int
}

enum WatchlistImportError: LocalizedError {
    case unsupportedVersion(Int)
    case missingCustomList(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version): "Backupversion \(version) stöds inte."
        case .missingCustomList(let id): "Listinnehåll saknar lista med ID \(id)."
        }
    }
}

@MainActor
enum WatchlistImportService {
    static func preview(_ backup: WatchlistBackup, in context: ModelContext) throws -> WatchlistImportPreview {
        try backup.validate()
        let library = try context.fetch(FetchDescriptor<LibraryEntry>())
        let episodeStates = try context.fetch(FetchDescriptor<EpisodeProgress>())
        let history = try context.fetch(FetchDescriptor<EpisodeWatchEvent>())
        let movieHistory = try context.fetch(FetchDescriptor<MovieWatchEvent>())
        let lists = try context.fetch(FetchDescriptor<CustomList>())
        let listItems = try context.fetch(FetchDescriptor<CustomListItem>())
        let reminders = try context.fetch(FetchDescriptor<PremiereReminder>())

        let existingLibrary = Set(library.map(\.stableID))
        let incomingLibrary = Set(backup.library.map(\.stableID))
        let existingState = Set(episodeStates.map(\.stableID))
        let existingHistory = Set(history.map(\.id))
        let existingMovieHistory = Set(movieHistory.map(\.id))
        let existingLists = Set(lists.map(\.id))
        let existingListItems = Set(listItems.map(\.stableID))
        let existingReminders = Set(reminders.map(\.stableID))

        return WatchlistImportPreview(
            newLibraryItems: backup.library.filter { !existingLibrary.contains($0.stableID) }.count,
            matchingLibraryItems: backup.library.filter { existingLibrary.contains($0.stableID) }.count,
            localOnlyLibraryItems: existingLibrary.subtracting(incomingLibrary).count,
            newEpisodeStates: backup.episodeProgress.filter { !existingState.contains($0.stableID) }.count,
            newHistoryEvents: backup.episodeHistory.filter { !existingHistory.contains($0.id) }.count,
            newMovieHistoryEvents: (backup.movieHistory ?? []).filter { !existingMovieHistory.contains($0.id) }.count,
            newCustomLists: backup.customLists.filter { !existingLists.contains($0.id) }.count,
            newCustomListItems: backup.customListItems.filter { !existingListItems.contains($0.stableID) }.count,
            newReminders: backup.premiereReminders.filter { !existingReminders.contains($0.stableID) }.count
        )
    }

    /// Merge is additive: existing local records are never overwritten or deleted.
    static func merge(_ backup: WatchlistBackup, into context: ModelContext) throws -> WatchlistImportPreview {
        let summary = try preview(backup, in: context)
        let library = try context.fetch(FetchDescriptor<LibraryEntry>())
        let states = try context.fetch(FetchDescriptor<EpisodeProgress>())
        let history = try context.fetch(FetchDescriptor<EpisodeWatchEvent>())
        let movieHistory = try context.fetch(FetchDescriptor<MovieWatchEvent>())
        let lists = try context.fetch(FetchDescriptor<CustomList>())
        let listItems = try context.fetch(FetchDescriptor<CustomListItem>())
        let reminders = try context.fetch(FetchDescriptor<PremiereReminder>())

        let libraryByID = Dictionary(library.map { ($0.stableID, $0) }, uniquingKeysWith: { first, _ in first })
        let stateIDs = Set(states.map(\.stableID))
        let historyIDs = Set(history.map(\.id))
        let movieHistoryIDs = Set(movieHistory.map(\.id))
        let listIDs = Set(lists.map(\.id))
        let listItemIDs = Set(listItems.map(\.stableID))
        let reminderIDs = Set(reminders.map(\.stableID))

        for record in backup.library where libraryByID[record.stableID] == nil {
            let item = MediaItem(
                id: record.tmdbID,
                kind: MediaKind(rawValue: record.mediaKind) ?? .movie,
                title: record.title,
                overview: record.overview,
                posterPath: record.posterPath,
                backdropPath: record.backdropPath,
                releaseDate: record.releaseDate,
                voteAverage: record.voteAverage
            )
            let entry = LibraryEntry(item: item, status: LibraryStatus(rawValue: record.statusRawValue) ?? .wantToWatch)
            entry.dateAdded = record.dateAdded
            entry.dateUpdated = record.dateUpdated
            entry.isFavorite = record.isFavorite
            entry.personalRating = record.personalRating
            entry.personalNotes = record.personalNotes
            entry.episodeTotalCount = record.episodeTotalCount
            entry.nextEpisodeTitle = record.nextEpisodeTitle
            entry.nextEpisodeCode = record.nextEpisodeCode
            entry.nextEpisodeAirDate = record.nextEpisodeAirDate
            context.insert(entry)
        }

        for record in backup.episodeProgress where !stateIDs.contains(record.stableID) {
            let episode = TVEpisode(
                id: record.episodeID,
                name: record.episodeTitle,
                overview: "",
                episodeNumber: record.episodeNumber,
                seasonNumber: record.seasonNumber,
                airDate: record.airDate,
                runtime: nil,
                stillPath: nil,
                voteAverage: 0
            )
            let state = EpisodeProgress(seriesID: record.seriesID, episode: episode, isWatched: record.isWatched)
            state.watchedAt = record.watchedAt
            state.dateUpdated = record.dateUpdated
            context.insert(state)
        }

        for record in backup.episodeHistory where !historyIDs.contains(record.id) {
            let event = EpisodeWatchEvent(
                id: record.id,
                seriesID: record.seriesID,
                episodeID: record.episodeID,
                seasonNumber: record.seasonNumber,
                episodeNumber: record.episodeNumber,
                episodeTitle: record.episodeTitle,
                watchedAt: record.watchedAt,
                source: record.sourceRawValue
            )
            context.insert(event)
        }

        for record in (backup.movieHistory ?? []) where !movieHistoryIDs.contains(record.id) {
            context.insert(MovieWatchEvent(
                id: record.id,
                tmdbID: record.tmdbID,
                title: record.title,
                posterPath: record.posterPath,
                watchedAt: record.watchedAt,
                source: record.sourceRawValue
            ))
        }

        for record in backup.customLists where !listIDs.contains(record.id) {
            let list = CustomList(id: record.id, name: record.name, createdAt: record.createdAt, updatedAt: record.updatedAt)
            context.insert(list)
        }

        let allListIDs = Set(lists.map(\.id)).union(backup.customLists.map(\.id))
        for record in backup.customListItems where !listItemIDs.contains(record.stableID) {
            guard allListIDs.contains(record.listID) else {
                throw WatchlistImportError.missingCustomList(record.listID)
            }
            let item = MediaItem(
                id: record.tmdbID,
                kind: MediaKind(rawValue: record.mediaKind) ?? .movie,
                title: record.title,
                overview: record.overview,
                posterPath: record.posterPath,
                backdropPath: record.backdropPath,
                releaseDate: record.releaseDate,
                voteAverage: record.voteAverage
            )
            let membership = CustomListItem(listID: record.listID, item: item)
            membership.dateAdded = record.dateAdded
            context.insert(membership)
        }

        for record in backup.premiereReminders where !reminderIDs.contains(record.stableID) {
            let reminder = PremiereReminder(
                stableID: record.stableID,
                tmdbID: record.tmdbID,
                mediaKind: record.mediaKind,
                title: record.title,
                premiereDate: record.premiereDate,
                leadDays: record.leadDays,
                notificationID: record.notificationID,
                dateCreated: record.dateCreated
            )
            context.insert(reminder)
        }

        try context.save()
        return summary
    }
}
