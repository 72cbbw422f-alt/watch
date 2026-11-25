import XCTest
@testable import WATCHLIST

final class TVEpisodeModelsTests: XCTestCase {
    func testDecodesSeriesSeasonListAndExcludesSpecialsFromRegularSeasons() throws {
        let json = """
        {
          "id": 1396,
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
}
