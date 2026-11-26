import Foundation
import SwiftData

struct WatchlistBackup: Codable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let exportedAt: Date
    let library: [LibraryRecord]
    let episodeProgress: [EpisodeProgressRecord]
    let episodeHistory: [EpisodeHistoryRecord]
    let movieHistory: [MovieHistoryRecord]?
    let customLists: [CustomListRecord]
    let customListItems: [CustomListItemRecord]
    let premiereReminders: [PremiereReminderRecord]

    init(
        exportedAt: Date = .now,
        library: [LibraryRecord],
        episodeProgress: [EpisodeProgressRecord],
        episodeHistory: [EpisodeHistoryRecord],
        movieHistory: [MovieHistoryRecord] = [],
        customLists: [CustomListRecord],
        customListItems: [CustomListItemRecord],
        premiereReminders: [PremiereReminderRecord]
    ) {
        schemaVersion = Self.currentSchemaVersion
        self.exportedAt = exportedAt
        self.library = library
        self.episodeProgress = episodeProgress
        self.episodeHistory = episodeHistory
        self.movieHistory = movieHistory
        self.customLists = customLists
        self.customListItems = customListItems
        self.premiereReminders = premiereReminders
    }

    func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw WatchlistBackupError.unsupportedVersion(schemaVersion)
        }
        guard library.allSatisfy({ !$0.stableID.isEmpty && $0.tmdbID > 0 && !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            throw WatchlistBackupError.invalidLibraryRecord
        }
        guard library.allSatisfy({
            guard let kind = MediaKind(rawValue: $0.mediaKind),
                  LibraryStatus(rawValue: $0.statusRawValue) != nil,
                  ($0.personalRating.map { (1...10).contains($0) } ?? true) else {
                return false
            }
            return $0.stableID == "\(kind.rawValue)-\($0.tmdbID)"
        }) else {
            throw WatchlistBackupError.invalidLibraryRecord
        }
        guard episodeProgress.allSatisfy({
            $0.stableID == EpisodeProgress.makeStableID(
                seriesID: $0.seriesID,
                seasonNumber: $0.seasonNumber,
                episodeNumber: $0.episodeNumber
            ) &&
            $0.seriesID > 0 &&
            $0.episodeID > 0 &&
            $0.seasonNumber >= 0 &&
            $0.episodeNumber > 0 &&
            !$0.episodeTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) else {
            throw WatchlistBackupError.invalidEpisodeRecord
        }
        guard episodeHistory.allSatisfy({ $0.seriesID > 0 && $0.episodeID > 0 && $0.seasonNumber >= 0 && $0.episodeNumber > 0 && !$0.episodeTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            throw WatchlistBackupError.invalidEpisodeRecord
        }
        guard (movieHistory ?? []).allSatisfy({ $0.tmdbID > 0 && !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            throw WatchlistBackupError.invalidMovieHistoryRecord
        }
        guard Set((movieHistory ?? []).map(\.id)).count == (movieHistory ?? []).count else {
            throw WatchlistBackupError.duplicateIdentity
        }
        guard customLists.allSatisfy({ !$0.id.isEmpty && !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            throw WatchlistBackupError.invalidCustomList
        }
        guard customListItems.allSatisfy({
            guard !$0.listID.isEmpty, $0.tmdbID > 0,
                  let kind = MediaKind(rawValue: $0.mediaKind) else {
                return false
            }
            let expectedMediaID = "\(kind.rawValue)-\($0.tmdbID)"
            return $0.mediaStableID == expectedMediaID &&
                $0.stableID == "\($0.listID)::\(expectedMediaID)"
        }) else {
            throw WatchlistBackupError.invalidCustomListItem
        }
        guard premiereReminders.allSatisfy({
            guard $0.tmdbID > 0,
                  let kind = MediaKind(rawValue: $0.mediaKind),
                  !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  (0...7).contains($0.leadDays) else {
                return false
            }
            return $0.stableID == "\(kind.rawValue)-\($0.tmdbID)"
        }) else {
            throw WatchlistBackupError.invalidReminder
        }
        let listIDs = Set(customLists.map(\.id))
        guard customListItems.allSatisfy({ listIDs.contains($0.listID) }) else {
            throw WatchlistBackupError.invalidCustomListItem
        }
        guard Set(library.map(\.stableID)).count == library.count,
              Set(episodeProgress.map(\.stableID)).count == episodeProgress.count,
              Set(episodeHistory.map(\.id)).count == episodeHistory.count,
              listIDs.count == customLists.count,
              Set(customListItems.map(\.stableID)).count == customListItems.count,
              Set(premiereReminders.map(\.stableID)).count == premiereReminders.count else {
            throw WatchlistBackupError.duplicateIdentity
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

struct MovieHistoryRecord: Codable {
    let id: UUID
    let tmdbID: Int
    let title: String
    let posterPath: String?
    let watchedAt: Date
    let sourceRawValue: String

    init(_ value: MovieWatchEvent) {
        id = value.id
        tmdbID = value.tmdbID
        title = value.title
        posterPath = value.posterPath
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
    case invalidEpisodeRecord
    case invalidMovieHistoryRecord
    case invalidCustomList
    case invalidCustomListItem
    case invalidReminder
    case duplicateIdentity

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version):
            "Backupversion \(version) stöds inte."
        case .invalidLibraryRecord:
            "Backupfilen innehåller en ogiltig film- eller seriepost."
        case .invalidEpisodeRecord:
            "Backupfilen innehåller en ogiltig avsnittspost."
        case .invalidMovieHistoryRecord:
            "Backupfilen innehåller en ogiltig filmhistorikpost."
        case .invalidCustomList:
            "Backupfilen innehåller en ogiltig egen lista."
        case .invalidCustomListItem:
            "Backupfilen innehåller ett ogiltigt listinnehåll."
        case .invalidReminder:
            "Backupfilen innehåller en ogiltig premiumpåminnelse."
        case .duplicateIdentity:
            "Backupfilen innehåller dubbla identiteter."
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
            movieHistory: try context.fetch(FetchDescriptor<MovieWatchEvent>()).map(MovieHistoryRecord.init),
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
