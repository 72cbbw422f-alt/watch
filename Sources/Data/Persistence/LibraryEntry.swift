import Foundation
import SwiftData

@Model
final class LibraryEntry {
    @Attribute(.unique) var stableID: String
    var tmdbID: Int
    var mediaKind: String
    var title: String
    var overview: String
    var posterPath: String?
    var backdropPath: String?
    var releaseDate: String?
    var voteAverage: Double
    var statusRawValue: String
    var dateAdded: Date
    var dateUpdated: Date
    var isFavorite: Bool
    var personalRating: Int?
    var personalNotes: String = ""
    var episodeTotalCount: Int?
    var nextEpisodeTitle: String?
    var nextEpisodeCode: String?
    var nextEpisodeAirDate: String?

    init(item: MediaItem, status: LibraryStatus = .wantToWatch) {
        stableID = item.stableID
        tmdbID = item.id
        mediaKind = item.kind.rawValue
        title = item.title
        overview = item.overview
        posterPath = item.posterPath
        backdropPath = item.backdropPath
        releaseDate = item.releaseDate
        voteAverage = item.voteAverage
        statusRawValue = status.rawValue
        dateAdded = .now
        dateUpdated = .now
        isFavorite = false
        personalRating = nil
        personalNotes = ""
    }

    var status: LibraryStatus {
        get { LibraryStatus(rawValue: statusRawValue) ?? .wantToWatch }
        set {
            statusRawValue = newValue.rawValue
            dateUpdated = .now
        }
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

enum LibraryStatus: String, CaseIterable, Identifiable {
    case wantToWatch
    case monitoring
    case watching
    case watched

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wantToWatch: "Vill se"
        case .monitoring: "Bevakar"
        case .watching: "Tittar på"
        case .watched: "Sedd"
        }
    }

    var symbol: String {
        switch self {
        case .wantToWatch: "bookmark"
        case .monitoring: "bell.badge"
        case .watching: "play.circle"
        case .watched: "checkmark.circle"
        }
    }
}
