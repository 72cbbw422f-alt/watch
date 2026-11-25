import Foundation
import SwiftData

@Model
final class EpisodeProgress {
    @Attribute(.unique) var stableID: String
    var seriesID: Int
    var seasonNumber: Int
    var episodeNumber: Int
    var episodeID: Int
    var episodeTitle: String
    var airDate: String?
    var isWatched: Bool
    var watchedAt: Date?
    var dateUpdated: Date

    init(seriesID: Int, episode: TVEpisode, isWatched: Bool = false) {
        stableID = Self.makeStableID(
            seriesID: seriesID,
            seasonNumber: episode.seasonNumber,
            episodeNumber: episode.episodeNumber
        )
        self.seriesID = seriesID
        seasonNumber = episode.seasonNumber
        episodeNumber = episode.episodeNumber
        episodeID = episode.id
        episodeTitle = episode.name
        airDate = episode.airDate
        self.isWatched = isWatched
        watchedAt = isWatched ? .now : nil
        dateUpdated = .now
    }

    static func makeStableID(seriesID: Int, seasonNumber: Int, episodeNumber: Int) -> String {
        "tv-\(seriesID)-s\(seasonNumber)-e\(episodeNumber)"
    }

    func setWatched(_ watched: Bool) {
        isWatched = watched
        watchedAt = watched ? .now : nil
        dateUpdated = .now
    }
}
