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

    var episodeStableID: String {
        EpisodeProgress.makeStableID(
            seriesID: seriesID,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber
        )
    }
}
