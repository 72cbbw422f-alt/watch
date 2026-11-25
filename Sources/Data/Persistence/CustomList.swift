import Foundation
import SwiftData

@Model
final class CustomList {
    @Attribute(.unique) var id: String
    var name: String
    var createdAt: Date
    var updatedAt: Date

    init(name: String) {
        id = UUID().uuidString
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        createdAt = .now
        updatedAt = .now
    }
    init(id: String, name: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class CustomListItem {
    @Attribute(.unique) var stableID: String
    var listID: String
    var mediaStableID: String
    var tmdbID: Int
    var mediaKind: String
    var title: String
    var overview: String
    var posterPath: String?
    var backdropPath: String?
    var releaseDate: String?
    var voteAverage: Double
    var dateAdded: Date

    init(listID: String, item: MediaItem) {
        stableID = "\(listID)::\(item.stableID)"
        self.listID = listID
        mediaStableID = item.stableID
        tmdbID = item.id
        mediaKind = item.kind.rawValue
        title = item.title
        overview = item.overview
        posterPath = item.posterPath
        backdropPath = item.backdropPath
        releaseDate = item.releaseDate
        voteAverage = item.voteAverage
        dateAdded = .now
    }

    var mediaItem: MediaItem {
        MediaItem(
            id: tmdbID,
            kind: MediaKind(rawValue: mediaKind) ?? .movie,
            title: title,
            overview: overview,
            posterPath: posterPath,
            backdropPath: backdropPath,
            releaseDate: releaseDate,
            voteAverage: voteAverage
        )
    }
}
