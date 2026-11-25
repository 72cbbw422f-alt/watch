import Foundation
import SwiftData

/// Immutable record of one viewing action. Multiple events may exist for the same episode.
@Model
final class EpisodeWatchEvent {
    @Attribute(.unique) var id: UUID
    var seriesID: Int
    var episodeID: Int
    var seasonNumber: Int
    var episodeNumber: Int
    var episodeTitle: String
    var watchedAt: Date
    var sourceRawValue: String

    init(
        seriesID: Int,
        episode: TVEpisode,
        watchedAt: Date = .now,
        source: String = "manual"
    ) {
        id = UUID()
        self.seriesID = seriesID
        episodeID = episode.id
        seasonNumber = episode.seasonNumber
        episodeNumber = episode.episodeNumber
        episodeTitle = episode.name
        self.watchedAt = watchedAt
        sourceRawValue = source
    }

    init(
        id: UUID,
        seriesID: Int,
        episodeID: Int,
        seasonNumber: Int,
        episodeNumber: Int,
        episodeTitle: String,
        watchedAt: Date,
        source: String
    ) {
        self.id = id
        self.seriesID = seriesID
        self.episodeID = episodeID
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.episodeTitle = episodeTitle
        self.watchedAt = watchedAt
        sourceRawValue = source
    }

    var episodeStableID: String {
        EpisodeProgress.makeStableID(
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber
        )
    }
}
