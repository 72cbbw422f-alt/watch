import XCTest
@testable import WATCHLIST

final class TVEpisodeModelsTests: XCTestCase {
    func testDecodesSeriesSeasonListAndExcludesSpecialsFromRegularSeasons() throws {
        let json = """
        {
          "id": 1396,
          "next_episode_to_air": {
            "id": 62086,
            "name": "Next episode",
            "season_number": 1,
            "episode_number": 2,
            "air_date": "2008-01-27"
          },
          "seasons": [
            {
              "id": 900,
              "name": "Specials",
              "overview": "",
              "season_number": 0,
              "episode_count": 2,
              "poster_path": null,
              "air_date": null
            },
            {
              "id": 901,
              "name": "Season 1",
              "overview": "The beginning",
              "season_number": 1,
              "episode_count": 7,
              "poster_path": "/season.jpg",
              "air_date": "2008-01-20"
            }
          ]
        }
        """.data(using: .utf8)!

        let details = try JSONDecoder().decode(TVSeriesDetails.self, from: json)

        XCTAssertEqual(details.id, 1396)
        XCTAssertEqual(details.seasons.count, 2)
        XCTAssertEqual(details.regularSeasons.map(\.seasonNumber), [1])
        XCTAssertEqual(details.regularSeasons.first?.displayName, "Season 1")
        XCTAssertEqual(details.regularSeasons.first?.episodeCount, 7)
        XCTAssertEqual(details.nextEpisodeToAir?.displayCode, "S01:E02")
        XCTAssertEqual(details.nextEpisodeToAir?.airDate, "2008-01-27")
    }

    func testDecodesEpisodeAndBuildsSeasonEpisodeCode() throws {
        let json = """
        {
          "id": 62085,
          "name": "Pilot",
          "overview": "The first episode",
          "episode_number": 1,
          "season_number": 1,
          "air_date": "2008-01-20",
          "runtime": 58,
          "still_path": "/still.jpg",
          "vote_average": 8.1
        }
        """.data(using: .utf8)!

        let episode = try JSONDecoder().decode(TVEpisode.self, from: json)

        XCTAssertEqual(episode.id, 62085)
        XCTAssertEqual(episode.displayCode, "S01:E01")
        XCTAssertEqual(episode.runtime, 58)
        XCTAssertEqual(episode.airDate, "2008-01-20")
    }

    func testNextUnwatchedEpisodeSkipsWatchedEpisodesAndSpecials() throws {
        let json = """
        [
          {"id": 10, "name": "Special", "overview": "", "episode_number": 1, "season_number": 0, "air_date": null, "runtime": null, "still_path": null, "vote_average": 0},
          {"id": 11, "name": "Pilot", "overview": "", "episode_number": 1, "season_number": 1, "air_date": "2024-01-01", "runtime": 45, "still_path": null, "vote_average": 8},
          {"id": 12, "name": "The Next One", "overview": "", "episode_number": 2, "season_number": 1, "air_date": "2024-01-08", "runtime": 45, "still_path": null, "vote_average": 8},
          {"id": 13, "name": "Season Two", "overview": "", "episode_number": 1, "season_number": 2, "air_date": "2025-01-01", "runtime": 45, "still_path": null, "vote_average": 8}
        ]
        """.data(using: .utf8)!

        let episodes = try JSONDecoder().decode([TVEpisode].self, from: json)
        let watched = Set([
            EpisodeProgress.makeStableID(seriesID: 1396, seasonNumber: 1, episodeNumber: 1)
        ])

        let next = TVEpisodeSelection.nextUnwatchedEpisode(
            in: episodes,
            seriesID: 1396,
            watchedKeys: watched
        )

        XCTAssertEqual(next?.id, 12)
        XCTAssertEqual(next?.name, "The Next One")
        XCTAssertEqual(next?.displayCode, "S01:E02")
    }

    func testNextUnwatchedEpisodeReturnsNilWhenAllRegularEpisodesAreWatched() throws {
        let json = """
        [
          {"id": 11, "name": "Pilot", "overview": "", "episode_number": 1, "season_number": 1, "air_date": null, "runtime": null, "still_path": null, "vote_average": 0}
        ]
        """.data(using: .utf8)!
        let episodes = try JSONDecoder().decode([TVEpisode].self, from: json)
        let watched = Set([
            EpisodeProgress.makeStableID(seriesID: 1396, seasonNumber: 1, episodeNumber: 1)
        ])

        XCTAssertNil(
            TVEpisodeSelection.nextUnwatchedEpisode(
                in: episodes,
                seriesID: 1396,
                watchedKeys: watched
            )
        )
    }

}
