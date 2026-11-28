import Foundation

/// Decoder for Seenr's public `seenr-export/2` JSON format.
/// This layer is intentionally independent from SwiftData so files can be validated
/// and previewed before any local library records are changed.
struct SeenrImportPayload: Sendable {
    struct Title: Sendable {
        let tmdbID: Int
        let kind: String
        let title: String
        let year: Int?
        let status: String
        let rating: Int?
        let review: String?
        let favorite: Bool
        let addedAt: Date?
        let startedAt: Date?
        let completedAt: Date?
        let watchedAt: Date?
        let dates: [Date]
        let watchCount: Int
    }

    struct Episode: Sendable {
        let seriesID: Int
        let seriesTitle: String
        let season: Int
        let number: Int
        let title: String
        let tmdbID: Int?
        let airDate: String?
        let watchedAt: Date?
        let watchCount: Int
        let dates: [Date]
    }

    struct Rating: Sendable {
        let kind: String
        let tmdbID: Int
        let seriesID: Int?
        let season: Int?
        let episode: Int?
        let title: String
        let score: Double
        let review: String?
        let isSpoiler: Bool
        let createdAt: Date?
    }

    struct Viewing: Sendable {
        let kind: String
        let tmdbID: Int
        let title: String
        let seriesID: Int?
        let seriesTitle: String?
        let season: Int?
        let episode: Int?
        let watchedAt: Date
        let platform: String?
        let service: String?
        let memo: String?
    }

    let shows: [Title]
    let movies: [Title]
    let episodes: [Episode]
    let viewings: [Viewing]
    let ratings: [Rating]
    let warnings: [String]

    var totalTitles: Int { shows.count + movies.count }
}

enum SeenrExportError: LocalizedError {
    case invalidJSON
    case unsupportedFormat(String)
    case invalidRoot

    var errorDescription: String? {
        switch self {
        case .invalidJSON: "Filen är inte giltig JSON."
        case .unsupportedFormat(let value): "Seenr-formatet stöds inte: \(value)."
        case .invalidRoot: "Exportfilen saknar ett giltigt Seenr-bibliotek."
        }
    }
}

enum SeenrExportDecoder {
    static func decode(_ data: Data) throws -> SeenrImportPayload {
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        } catch {
            throw SeenrExportError.invalidJSON
        }
        guard let root = object as? [String: Any] else { throw SeenrExportError.invalidRoot }
        let format = root["format"] as? String ?? ""
        guard format == "seenr-export/2" else { throw SeenrExportError.unsupportedFormat(format.isEmpty ? "okänt" : format) }

        let shows = (root["shows"] as? [[String: Any]] ?? []).compactMap { title($0, kind: "television") }
        let movies = (root["movies"] as? [[String: Any]] ?? []).compactMap { title($0, kind: "movie") }
        let episodes = (root["episode_watches"] as? [[String: Any]] ?? []).compactMap(episode)
        let viewings = (root["viewings"] as? [[String: Any]] ?? []).compactMap(viewing)
        let ratings = (root["ratings"] as? [[String: Any]] ?? []).compactMap(rating)
        var warnings: [String] = []
        if root["shows"] == nil { warnings.append("Exporten saknar serien-listan.") }
        if root["movies"] == nil { warnings.append("Exporten saknar film-listan.") }
        if root["episode_watches"] == nil { warnings.append("Exporten saknar episode_watches; avsnittsprogress kan inte återskapas.") }
        if root["viewings"] == nil { warnings.append("Exporten saknar viewings; separat visningshistorik kan inte återskapas.") }
        if root["ratings"] == nil { warnings.append("Exporten saknar ratings; betyg på säsonger och avsnitt kan inte återskapas.") }
        let malformedTitles = (root["shows"] as? [[String: Any]] ?? []).count - shows.count
            + (root["movies"] as? [[String: Any]] ?? []).count - movies.count
        let malformedEpisodes = (root["episode_watches"] as? [[String: Any]] ?? []).count - episodes.count
        let malformedViewings = (root["viewings"] as? [[String: Any]] ?? []).count - viewings.count
        let malformedRatings = (root["ratings"] as? [[String: Any]] ?? []).count - ratings.count
        if malformedTitles > 0 { warnings.append("\(malformedTitles) film- eller serieposter saknade giltiga grunduppgifter och hoppas över.") }
        if malformedEpisodes > 0 { warnings.append("\(malformedEpisodes) avsnittsposter kunde inte läsas och hoppas över.") }
        if malformedViewings > 0 { warnings.append("\(malformedViewings) visningshändelser kunde inte läsas och hoppas över.") }
        if malformedRatings > 0 { warnings.append("\(malformedRatings) betygsposter kunde inte läsas och hoppas över.") }

        return SeenrImportPayload(shows: shows, movies: movies, episodes: episodes, viewings: viewings, ratings: ratings, warnings: warnings)
    }

    private static func title(_ value: [String: Any], kind: String) -> SeenrImportPayload.Title? {
        guard let id = integer(value["tmdb_id"]), id > 0,
              let name = value["title"] as? String, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let status = value["status"] as? String else { return nil }
        return .init(
            tmdbID: id, kind: kind, title: name,
            year: integer(value["year"]), status: status,
            rating: integer(value["rating"]), review: value["review"] as? String,
            favorite: value["favorite"] as? Bool ?? false,
            addedAt: date(value["added_at"]), startedAt: date(value["started_at"]),
            completedAt: date(value["completed_at"]), watchedAt: date(value["watched_at"]) ?? date(value["first_watched_at"]),
            dates: (value["dates"] as? [String] ?? []).compactMap(date),
            watchCount: max(0, integer(value["watch_count"]) ?? integer(value["plays"]) ?? 0)
        )
    }

    private static func episode(_ value: [String: Any]) -> SeenrImportPayload.Episode? {
        guard let seriesID = integer(value["show_tmdb_id"]), seriesID > 0,
              let season = integer(value["season"]), season >= 0,
              let number = integer(value["episode"]), number > 0,
              let name = value["episode_title"] as? String, !name.isEmpty else { return nil }
        let dates = (value["dates"] as? [String] ?? []).compactMap(date)
        return .init(
            seriesID: seriesID, seriesTitle: value["show_title"] as? String ?? "",
            season: season, number: number, title: name,
            tmdbID: integer(value["episode_tmdb_id"]), airDate: value["air_date"] as? String,
            watchedAt: date(value["watched_at"]) ?? dates.last,
            watchCount: max(1, integer(value["watch_count"]) ?? 1), dates: dates
        )
    }

    private static func rating(_ value: [String: Any]) -> SeenrImportPayload.Rating? {
        guard let kind = value["type"] as? String,
              let work = value["work"] as? [String: Any],
              let id = integer(work["tmdb_id"]), id > 0,
              let score = (value["score"] as? NSNumber)?.doubleValue else { return nil }
        return .init(
            kind: kind, tmdbID: id,
            seriesID: integer(work["show_tmdb_id"]),
            season: integer(work["season"]), episode: integer(work["episode"]),
            title: work["title"] as? String ?? work["show_title"] as? String ?? "",
            score: score, review: value["review"] as? String,
            isSpoiler: value["is_spoiler"] as? Bool ?? false,
            createdAt: date(value["created_at"])
        )
    }

    private static func viewing(_ value: [String: Any]) -> SeenrImportPayload.Viewing? {
        guard let kind = value["type"] as? String,
              let work = value["work"] as? [String: Any],
              let id = integer(work["tmdb_id"]), id > 0,
              let name = work["title"] as? String ?? work["show_title"] as? String,
              let watchedAt = date(value["watched_at"]) else { return nil }
        return .init(
            kind: kind, tmdbID: id, title: name,
            seriesID: integer(work["show_tmdb_id"]),
            seriesTitle: work["show_title"] as? String,
            season: integer(work["season"]), episode: integer(work["episode"]),
            watchedAt: watchedAt, platform: value["platform"] as? String,
            service: value["service"] as? String, memo: value["memo"] as? String
        )
    }

    private static func integer(_ value: Any?) -> Int? {
        if let number = value as? NSNumber { return number.intValue }
        if let string = value as? String { return Int(string) }
        return nil
    }

    private static func date(_ value: Any?) -> Date? {
        guard let string = value as? String else { return nil }
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let parsed = fractional.date(from: string) { return parsed }
        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]
        return standard.date(from: string)
    }
}
