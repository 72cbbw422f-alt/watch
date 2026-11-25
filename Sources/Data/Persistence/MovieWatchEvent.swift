import Foundation
import SwiftData

/// Immutable record of one movie viewing. Rewatches are stored as separate events.
@Model
final class MovieWatchEvent {
    @Attribute(.unique) var id: UUID
    var tmdbID: Int
    var title: String
    var posterPath: String?
    var watchedAt: Date
    var sourceRawValue: String

    init(
        tmdbID: Int,
        title: String,
        posterPath: String? = nil,
        watchedAt: Date = .now,
        source: String = "manual"
    ) {
        id = UUID()
        self.tmdbID = tmdbID
        self.title = title
        self.posterPath = posterPath
        self.watchedAt = watchedAt
        sourceRawValue = source
    }

    init(
        id: UUID,
        tmdbID: Int,
        title: String,
        posterPath: String?,
        watchedAt: Date,
        source: String
    ) {
        self.id = id
        self.tmdbID = tmdbID
        self.title = title
        self.posterPath = posterPath
        self.watchedAt = watchedAt
        sourceRawValue = source
    }
}
