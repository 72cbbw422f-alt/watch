import Foundation

enum MediaKind: String, Codable, CaseIterable, Sendable {
    case movie
    case television

    var displayName: String {
        switch self {
        case .movie: "Film"
        case .television: "Serie"
        }
    }

    var tmdbPath: String {
        switch self {
        case .movie: "movie"
        case .television: "tv"
        }
    }
}

struct MediaItem: Identifiable, Codable, Hashable, Sendable {
    let id: Int
    let kind: MediaKind
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double
    let originalLanguage: String?
    let isAdult: Bool

    var isAllowedForDiscovery: Bool {
        guard !isAdult else { return false }
        let language = (originalLanguage ?? "").lowercased()
        return language != "ja" && language != "zh"
    }

    var stableID: String { "\(kind.rawValue)-\(id)" }

    var posterURL: URL? {
        imageURL(path: posterPath, size: "w500")
    }

    var backdropURL: URL? {
        imageURL(path: backdropPath, size: "w1280")
    }

    private func imageURL(path: String?, size: String) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/\(size)\(path)")
    }

    enum CodingKeys: String, CodingKey {
        case id, title, name, overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case originalLanguage = "original_language"
        case isAdult = "adult"
    }

    init(
        id: Int,
        kind: MediaKind,
        title: String,
        overview: String,
        posterPath: String? = nil,
        backdropPath: String? = nil,
        releaseDate: String? = nil,
        voteAverage: Double = 0,
        originalLanguage: String? = nil,
        isAdult: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
        self.originalLanguage = originalLanguage
        self.isAdult = isAdult
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        overview = try values.decodeIfPresent(String.self, forKey: .overview) ?? ""
        posterPath = try values.decodeIfPresent(String.self, forKey: .posterPath)
        backdropPath = try values.decodeIfPresent(String.self, forKey: .backdropPath)
        voteAverage = try values.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        originalLanguage = try values.decodeIfPresent(String.self, forKey: .originalLanguage)
        isAdult = try values.decodeIfPresent(Bool.self, forKey: .isAdult) ?? false

        if let movieTitle = try values.decodeIfPresent(String.self, forKey: .title) {
            kind = .movie
            title = movieTitle
            releaseDate = try values.decodeIfPresent(String.self, forKey: .releaseDate)
        } else {
            kind = .television
            title = try values.decodeIfPresent(String.self, forKey: .name) ?? ""
            releaseDate = try values.decodeIfPresent(String.self, forKey: .firstAirDate)
        }
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(kind == .movie ? title : nil, forKey: .title)
        try values.encode(kind == .television ? title : nil, forKey: .name)
        try values.encode(overview, forKey: .overview)
        try values.encodeIfPresent(posterPath, forKey: .posterPath)
        try values.encodeIfPresent(backdropPath, forKey: .backdropPath)
        try values.encodeIfPresent(releaseDate, forKey: kind == .movie ? .releaseDate : .firstAirDate)
        try values.encode(voteAverage, forKey: .voteAverage)
        try values.encodeIfPresent(originalLanguage, forKey: .originalLanguage)
        try values.encode(isAdult, forKey: .isAdult)
    }
}
