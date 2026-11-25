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
        as responseType: Response.Type
    ) async throws -> Response {
        guard !accessToken.isEmpty else { throw TMDBError.missingAccessToken }

        var components = URLComponents(
            url: baseURL.appending(path: path),
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
