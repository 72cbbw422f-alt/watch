import Foundation
import SwiftData

struct WatchlistBackup: Codable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let exportedAt: Date
    let library: [LibraryRecord]
    let episodeProgress: [EpisodeProgressRecord]
    let episodeHistory: [EpisodeHistoryRecord]
    let customLists: [CustomListRecord]
    let customListItems: [CustomListItemRecord]
    let premiereReminders: [PremiereReminderRecord]

    init(
        exportedAt: Date = .now,
        library: [LibraryRecord],
        episodeProgress: [EpisodeProgressRecord],
        episodeHistory: [EpisodeHistoryRecord],
        customLists: [CustomListRecord],
        customListItems: [CustomListItemRecord],
        premiereReminders: [PremiereReminderRecord]
    ) {
        schemaVersion = Self.currentSchemaVersion
        self.exportedAt = exportedAt
        self.library = library
        self.episodeProgress = episodeProgress
        self.episodeHistory = episodeHistory
        self.customLists = customLists
        self.customListItems = customListItems
        self.premiereReminders = premiereReminders
    }

    func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw WatchlistBackupError.unsupportedVersion(schemaVersion)
        }
        guard library.allSatisfy({ !$0.stableID.isEmpty && $0.tmdbID > 0 && !$0.title.isEmpty }) else {
            throw WatchlistBackupError.invalidLibraryRecord
        }
        guard customLists.allSatisfy({ !$0.id.isEmpty && !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            throw WatchlistBackupError.invalidCustomList
        }
        guard customListItems.allSatisfy({ !$0.stableID.isEmpty && !$0.listID.isEmpty && !$0.mediaStableID.isEmpty }) else {
            throw WatchlistBackupError.invalidCustomListItem
        }
    }
}

struct LibraryRecord: Codable {
    let stableID: String
    let tmdbID: Int
    let mediaKind: String
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double
    let statusRawValue: String
    let dateAdded: Date
    let dateUpdated: Date
    let isFavorite: Bool
    let personalRating: Int?
    let personalNotes: String
    let episodeTotalCount: Int?
    let nextEpisodeTitle: String?
    let nextEpisodeCode: String?
    let nextEpisodeAirDate: String?

    init(_ entry: LibraryEntry) {
        stableID = entry.stableID
        tmdbID = entry.tmdbID
        mediaKind = entry.mediaKind
        title = entry.title
        overview = entry.overview
        posterPath = entry.posterPath
        backdropPath = entry.backdropPath
        releaseDate = entry.releaseDate
        voteAverage = entry.voteAverage
        statusRawValue = entry.statusRawValue
        dateAdded = entry.dateAdded
        dateUpdated = entry.dateUpdated
        isFavorite = entry.isFavorite
        personalRating = entry.personalRating
        personalNotes = entry.personalNotes
        episodeTotalCount = entry.episodeTotalCount
        nextEpisodeTitle = entry.nextEpisodeTitle
        nextEpisodeCode = entry.nextEpisodeCode
        nextEpisodeAirDate = entry.nextEpisodeAirDate
    }
}

struct EpisodeProgressRecord: Codable {
    let stableID: String
    let seriesID: Int
    let seasonNumber: Int
    let episodeNumber: Int
    let episodeID: Int
    let episodeTitle: String
    let airDate: String?
    let isWatched: Bool
    let watchedAt: Date?
    let dateUpdated: Date

    init(_ value: EpisodeProgress) {
        stableID = value.stableID
        seriesID = value.seriesID
        seasonNumber = value.seasonNumber
        episodeNumber = value.episodeNumber
        episodeID = value.episodeID
        episodeTitle = value.episodeTitle
        airDate = value.airDate
        isWatched = value.isWatched
        watchedAt = value.watchedAt
        dateUpdated = value.dateUpdated
    }
}

struct EpisodeHistoryRecord: Codable {
    let id: UUID
    let seriesID: Int
    let episodeID: Int
    let seasonNumber: Int
    let episodeNumber: Int
    let episodeTitle: String
    let watchedAt: Date
    let sourceRawValue: String

    init(_ value: EpisodeWatchEvent) {
        id = value.id
        seriesID = value.seriesID
        episodeID = value.episodeID
        seasonNumber = value.seasonNumber
        episodeNumber = value.episodeNumber
        episodeTitle = value.episodeTitle
        watchedAt = value.watchedAt
        sourceRawValue = value.sourceRawValue
    }
}

struct CustomListRecord: Codable {
    let id: String
    let name: String
    let createdAt: Date
    let updatedAt: Date

    init(_ value: CustomList) {
        id = value.id
        name = value.name
        createdAt = value.createdAt
        updatedAt = value.updatedAt
    }
}

struct CustomListItemRecord: Codable {
    let stableID: String
    let listID: String
    let mediaStableID: String
    let tmdbID: Int
    let mediaKind: String
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double
    let dateAdded: Date

    init(_ value: CustomListItem) {
        stableID = value.stableID
        listID = value.listID
        mediaStableID = value.mediaStableID
        tmdbID = value.tmdbID
        mediaKind = value.mediaKind
        title = value.title
        overview = value.overview
        posterPath = value.posterPath
        backdropPath = value.backdropPath
        releaseDate = value.releaseDate
        voteAverage = value.voteAverage
        dateAdded = value.dateAdded
    }
}

struct PremiereReminderRecord: Codable {
    let stableID: String
    let tmdbID: Int
    let mediaKind: String
    let title: String
    let premiereDate: Date
    let leadDays: Int
    let notificationID: String
    let dateCreated: Date

    init(_ value: PremiereReminder) {
        stableID = value.stableID
        tmdbID = value.tmdbID
        mediaKind = value.mediaKind
        title = value.title
        premiereDate = value.premiereDate
        leadDays = value.leadDays
        notificationID = value.notificationID
        dateCreated = value.dateCreated
    }
}

enum WatchlistBackupError: LocalizedError {
    case unsupportedVersion(Int)
    case invalidLibraryRecord
    case invalidCustomList
    case invalidCustomListItem

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version):
            "Backupversion \(version) stöds inte."
        case .invalidLibraryRecord:
            "Backupfilen innehåller en ogiltig bibliotekspost."
        case .invalidCustomList:
            "Backupfilen innehåller en ogiltig egen lista."
        case .invalidCustomListItem:
            "Backupfilen innehåller ett ogiltigt listinnehåll."
        }
    }
}

enum WatchlistBackupService {
    static func makeBackup(from context: ModelContext, exportedAt: Date = .now) throws -> WatchlistBackup {
        WatchlistBackup(
            exportedAt: exportedAt,
            library: try context.fetch(FetchDescriptor<LibraryEntry>()).map(LibraryRecord.init),
            episodeProgress: try context.fetch(FetchDescriptor<EpisodeProgress>()).map(EpisodeProgressRecord.init),
            episodeHistory: try context.fetch(FetchDescriptor<EpisodeWatchEvent>()).map(EpisodeHistoryRecord.init),
            customLists: try context.fetch(FetchDescriptor<CustomList>()).map(CustomListRecord.init),
            customListItems: try context.fetch(FetchDescriptor<CustomListItem>()).map(CustomListItemRecord.init),
            premiereReminders: try context.fetch(FetchDescriptor<PremiereReminder>()).map(PremiereReminderRecord.init)
        )
    }

    static func encode(_ backup: WatchlistBackup) throws -> Data {
        try backup.validate()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(backup)
    }

    static func decode(_ data: Data) throws -> WatchlistBackup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(WatchlistBackup.self, from: data)
        try backup.validate()
        return backup
    }
}
