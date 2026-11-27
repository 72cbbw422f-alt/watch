import Foundation

struct TVSeriesDetails: Decodable, Sendable {
    let id: Int
    let seasons: [TVSeason]
    let nextEpisodeToAir: TVNextEpisode?
    let lastEpisodeToAir: TVNextEpisode?

    enum CodingKeys: String, CodingKey {
        case id, seasons
        case nextEpisodeToAir = "next_episode_to_air"
        case lastEpisodeToAir = "last_episode_to_air"
    }

    var regularSeasons: [TVSeason] {
        seasons
            .filter { $0.seasonNumber > 0 }
            .sorted { $0.seasonNumber < $1.seasonNumber }
    }
}

struct TVNextEpisode: Decodable, Sendable {
    let id: Int
    let name: String
    let seasonNumber: Int
    let episodeNumber: Int
    let airDate: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case seasonNumber = "season_number"
        case episodeNumber = "episode_number"
        case airDate = "air_date"
    }

    var displayCode: String { String(format: "S%02d:E%02d", seasonNumber, episodeNumber) }
}

struct TVSeason: Decodable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let overview: String
    let seasonNumber: Int
    let episodeCount: Int
    let posterPath: String?
    let airDate: String?

    enum CodingKeys: String, CodingKey {
        case id, name, overview
        case seasonNumber = "season_number"
        case episodeCount = "episode_count"
        case posterPath = "poster_path"
        case airDate = "air_date"
    }

    var displayName: String {
        name.isEmpty ? "Säsong \(seasonNumber)" : name
    }
}

struct TVSeasonDetails: Decodable, Sendable {
    let id: Int
    let seasonNumber: Int
    let episodes: [TVEpisode]

    enum CodingKeys: String, CodingKey {
        case id, episodes
        case seasonNumber = "season_number"
    }
}

struct TVEpisode: Decodable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let overview: String
    let episodeNumber: Int
    let seasonNumber: Int
    let airDate: String?
    let runtime: Int?
    let stillPath: String?
    let voteAverage: Double

    enum CodingKeys: String, CodingKey {
        case id, name, overview, runtime
        case episodeNumber = "episode_number"
        case seasonNumber = "season_number"
        case airDate = "air_date"
        case stillPath = "still_path"
        case voteAverage = "vote_average"
    }

    var displayCode: String {
        String(format: "S%02d:E%02d", seasonNumber, episodeNumber)
    }
}
