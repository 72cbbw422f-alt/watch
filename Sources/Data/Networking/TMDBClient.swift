import Foundation

enum TMDBError: LocalizedError {
    case missingAccessToken
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .missingAccessToken:
            "TMDB-åtkomsttoken saknas. Lägg till TMDBAccessToken i appens konfiguration."
        case .invalidResponse:
            "Servern svarade med ett ogiltigt svar."
        case .httpStatus(let status):
            "TMDB returnerade HTTP-status \(status)."
        case .decodingFailed:
            "Svaret från TMDB kunde inte läsas."
        }
    }
}

protocol MediaSearching: Sendable {
    func searchMovies(query: String) async throws -> [MediaItem]
    func searchTelevision(query: String) async throws -> [MediaItem]
}

actor TMDBClient: MediaSearching {
    private let accessToken: String
    private let session: URLSession
    private let baseURL = URL(string: "https://api.themoviedb.org/3")!

    init(accessToken: String, session: URLSession = .shared) {
        self.accessToken = accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        self.session = session
    }

    func searchMovies(query: String) async throws -> [MediaItem] {
        try await search(query: query, kind: .movie)
    }

    func searchTelevision(query: String) async throws -> [MediaItem] {
        try await search(query: query, kind: .television)
    }

    func upcomingMovies() async throws -> [MediaItem] {
        let response = try await fetch(
            path: "/movie/upcoming",
            as: TMDBPagedMediaResponse.self,
            queryItems: [
                URLQueryItem(name: "language", value: "sv-SE"),
                URLQueryItem(name: "region", value: "SE"),
                URLQueryItem(name: "page", value: "1")
            ]
        )
        return response.results
    }

    func upcomingTelevisionPremieres(from date: Date = .now) async throws -> [MediaItem] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"

        let response = try await fetch(
            path: "/discover/tv",
            as: TMDBPagedMediaResponse.self,
            queryItems: [
                URLQueryItem(name: "language", value: "sv-SE"),
                URLQueryItem(name: "first_air_date.gte", value: formatter.string(from: date)),
                URLQueryItem(name: "sort_by", value: "first_air_date.asc"),
                URLQueryItem(name: "include_null_first_air_dates", value: "false"),
                URLQueryItem(name: "page", value: "1")
            ]
        )
        return response.results
    }

    func similarTitles(to item: MediaItem) async throws -> [MediaItem] {
        let response = try await fetch(
            path: "/\(item.kind.tmdbPath)/\(item.id)/similar",
            as: TMDBPagedMediaResponse.self,
            queryItems: [
                URLQueryItem(name: "language", value: "sv-SE"),
                URLQueryItem(name: "page", value: "1")
            ]
        )
        return response.results.filter { $0.id != item.id }
    }


    func reviews(for item: MediaItem, page: Int = 1) async throws -> TMDBReviewPage {
        try await fetch(
            path: "/\(item.kind.tmdbPath)/\(item.id)/reviews",
            as: TMDBReviewPage.self,
            queryItems: [
                URLQueryItem(name: "language", value: "en-US"),
                URLQueryItem(name: "page", value: String(max(1, page)))
            ]
        )
    }


    func videos(for item: MediaItem) async throws -> [TMDBVideo] {
        let response = try await fetch(
            path: "/\(item.kind.tmdbPath)/\(item.id)/videos",
            as: TMDBVideoPage.self,
            queryItems: [
                URLQueryItem(name: "language", value: "sv-SE")
            ]
        )
        return response.results.sorted { lhs, rhs in
            if lhs.isPreferredTrailer != rhs.isPreferredTrailer {
                return lhs.isPreferredTrailer
            }
            return lhs.publishedAt > rhs.publishedAt
        }
    }

    func televisionDetails(id: Int) async throws -> TVSeriesDetails {
        try await fetch(
            path: "/tv/\(id)",
            as: TVSeriesDetails.self
        )
    }

    func televisionSeason(id: Int, seasonNumber: Int) async throws -> TVSeasonDetails {
        try await fetch(
            path: "/tv/\(id)/season/\(seasonNumber)",
            as: TVSeasonDetails.self
        )
    }

    private func fetch<Response: Decodable & Sendable>(
        path: String,
        as responseType: Response.Type,
        queryItems: [URLQueryItem] = [
            URLQueryItem(name: "language", value: "sv-SE")
        ]
    ) async throws -> Response {
        guard !accessToken.isEmpty else { throw TMDBError.missingAccessToken }

        var components = URLComponents(
            url: baseURL.appending(path: path),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = queryItems
        guard let url = components?.url else { throw TMDBError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDBError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw TMDBError.httpStatus(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(responseType, from: data)
        } catch {
            throw TMDBError.decodingFailed
        }
    }

    func trendingThisWeek() async throws -> [MediaItem] {
        guard !accessToken.isEmpty else { throw TMDBError.missingAccessToken }

        var components = URLComponents(
            url: baseURL.appending(path: "/trending/all/week"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "language", value: "sv-SE")
        ]
        guard let url = components?.url else { throw TMDBError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDBError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw TMDBError.httpStatus(httpResponse.statusCode)
        }

        do {
            let payload = try JSONDecoder().decode(TMDBSearchResponse.self, from: data)
            return payload.results.compactMap { result in
                guard let kind = result.mediaKind else { return nil }
                return result.asMediaItem(kind: kind)
            }
        } catch {
            throw TMDBError.decodingFailed
        }
    }

    private func search(query: String, kind: MediaKind) async throws -> [MediaItem] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }
        guard !accessToken.isEmpty else { throw TMDBError.missingAccessToken }

        var components = URLComponents(
            url: baseURL.appending(path: "/search/\(kind.tmdbPath)"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "query", value: trimmedQuery),
            URLQueryItem(name: "language", value: "sv-SE"),
            URLQueryItem(name: "region", value: "SE"),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "page", value: "1")
        ]

        guard let url = components?.url else { throw TMDBError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDBError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw TMDBError.httpStatus(httpResponse.statusCode)
        }

        do {
            let payload = try JSONDecoder().decode(TMDBSearchResponse.self, from: data)
            return payload.results.map { $0.asMediaItem(kind: kind) }
        } catch {
            throw TMDBError.decodingFailed
        }
    }
}

private struct TMDBPagedMediaResponse: Decodable, Sendable {
    let results: [MediaItem]
}

private struct TMDBSearchResponse: Decodable {
    let results: [TMDBSearchResult]
}

private struct TMDBSearchResult: Decodable {
    let id: Int
    let title: String?
    let name: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let firstAirDate: String?
    let voteAverage: Double?
    let mediaType: String?

    enum CodingKeys: String, CodingKey {
        case id, title, name, overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case mediaType = "media_type"
    }

    var mediaKind: MediaKind? {
        switch mediaType {
        case "movie": .movie
        case "tv": .television
        default: nil
        }
    }

    func asMediaItem(kind: MediaKind) -> MediaItem {
        MediaItem(
            id: id,
            kind: kind,
            title: kind == .movie ? (title ?? "") : (name ?? ""),
            overview: overview ?? "",
            posterPath: posterPath,
            backdropPath: backdropPath,
            releaseDate: kind == .movie ? releaseDate : firstAirDate,
            voteAverage: voteAverage ?? 0
        )
    }
}


struct TMDBReviewPage: Decodable, Sendable {
    let page: Int
    let results: [TMDBReview]
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
    }
}

struct TMDBReview: Decodable, Identifiable, Sendable {
    let id: String
    let author: String
    let authorDetails: AuthorDetails
    let content: String
    let createdAt: String
    let url: URL?

    enum CodingKeys: String, CodingKey {
        case id, author, content, url
        case authorDetails = "author_details"
        case createdAt = "created_at"
    }

    struct AuthorDetails: Decodable, Sendable {
        let rating: Double?
    }
}


struct TMDBVideoPage: Decodable, Sendable {
    let results: [TMDBVideo]
}

struct TMDBVideo: Decodable, Identifiable, Sendable {
    let id: String
    let name: String
    let key: String
    let site: String
    let type: String
    let official: Bool
    let publishedAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, key, site, type, official
        case publishedAt = "published_at"
    }

    var isPreferredTrailer: Bool {
        type == "Trailer" && site == "YouTube"
    }

    var playbackURL: URL? {
        switch site {
        case "YouTube":
            URL(string: "https://www.youtube.com/watch?v=\(key)")
        case "Vimeo":
            URL(string: "https://vimeo.com/\(key)")
        default:
            nil
        }
    }
}
