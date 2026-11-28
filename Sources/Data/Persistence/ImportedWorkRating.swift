import Foundation
import SwiftData

/// Preserves Seenr season/episode ratings that do not have a native WATCHLIST rating field yet.
@Model
final class ImportedWorkRating {
    @Attribute(.unique) var stableID: String
    var kind: String
    var tmdbID: Int
    var seriesID: Int?
    var seasonNumber: Int?
    var episodeNumber: Int?
    var title: String
    var score: Double
    var review: String?
    var isSpoiler: Bool
    var createdAt: Date?

    init(
        stableID: String,
        kind: String,
        tmdbID: Int,
        seriesID: Int?,
        seasonNumber: Int?,
        episodeNumber: Int?,
        title: String,
        score: Double,
        review: String?,
        isSpoiler: Bool,
        createdAt: Date?
    ) {
        self.stableID = stableID
        self.kind = kind
        self.tmdbID = tmdbID
        self.seriesID = seriesID
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.title = title
        self.score = score
        self.review = review
        self.isSpoiler = isSpoiler
        self.createdAt = createdAt
    }
}
