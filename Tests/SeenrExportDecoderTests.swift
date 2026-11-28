import XCTest
@testable import WATCHLIST

final class SeenrExportDecoderTests: XCTestCase {
    func testDecodesSeenrVersionTwoTitlesEpisodesAndViewings() throws {
        let json = """
        {
          "format": "seenr-export/2",
          "shows": [{
            "tmdb_id": 125988, "title": "Silo", "year": 2023,
            "status": "watching", "rating": 8, "review": "Great",
            "favorite": true, "added_at": "2024-01-02T03:04:05Z",
            "started_at": "2024-01-03T03:04:05Z", "episodes_watched": 1
          }],
          "movies": [{
            "tmdb_id": 13, "title": "Forrest Gump", "year": 1994,
            "status": "completed", "rating": 10, "favorite": false,
            "watched_at": "1994-06-23T00:00:00Z", "watch_count": 2
          }],
          "episode_watches": [{
            "show_tmdb_id": 125988, "show_title": "Silo",
            "season": 1, "episode": 1, "episode_title": "Freedom Day",
            "episode_tmdb_id": 2964686, "air_date": "2023-05-04",
            "watched_at": null, "watch_count": 2,
            "dates": ["2023-05-05T00:00:00Z", "2023-05-06T00:00:00Z"]
          }],
          "viewings": [{
            "type": "episode",
            "work": {
              "type": "episode", "tmdb_id": 2964686,
              "show_tmdb_id": 125988, "season": 1, "episode": 1,
              "title": "Freedom Day", "show_title": "Silo"
            },
            "watched_at": "2023-05-05T00:00:00Z",
            "platform": "Apple TV+", "service": null, "memo": "Rewatch"
          }]
        }
        """
        let result = try SeenrExportDecoder.decode(Data(json.utf8))

        XCTAssertEqual(result.totalTitles, 2)
        XCTAssertEqual(result.shows.first?.status, "watching")
        XCTAssertEqual(result.shows.first?.rating, 8)
        XCTAssertEqual(result.shows.first?.favorite, true)
        XCTAssertEqual(result.movies.first?.watchCount, 2)
        XCTAssertEqual(result.episodes.first?.seriesID, 125988)
        XCTAssertEqual(result.episodes.first?.season, 1)
        XCTAssertEqual(result.episodes.first?.watchCount, 2)
        XCTAssertEqual(result.episodes.first?.dates.count, 2)
        XCTAssertEqual(result.viewings.first?.kind, "episode")
        XCTAssertEqual(result.viewings.first?.seriesID, 125988)
        XCTAssertEqual(result.viewings.first?.memo, "Rewatch")
        XCTAssertTrue(result.warnings.isEmpty)
    }

    func testRejectsUnsupportedSeenrFormat() {
        let data = Data(#"{"format":"seenr-export/1"}"#.utf8)
        XCTAssertThrowsError(try SeenrExportDecoder.decode(data)) { error in
            XCTAssertTrue(error is SeenrExportError)
        }
    }

    func testInvalidRecordsAreSkippedAndReported() throws {
        let json = """
        {
          "format": "seenr-export/2",
          "shows": [{"tmdb_id": 0, "title": "Invalid", "status": "watching"}],
          "movies": [],
          "episode_watches": [{"show_tmdb_id": 1, "season": 1, "episode": 0}],
          "viewings": [{"type": "movie", "work": {"tmdb_id": 10, "title": "No date"}}]
        }
        """
        let result = try SeenrExportDecoder.decode(Data(json.utf8))
        XCTAssertEqual(result.totalTitles, 0)
        XCTAssertTrue(result.episodes.isEmpty)
        XCTAssertTrue(result.viewings.isEmpty)
        XCTAssertEqual(result.warnings.count, 2)
    }
}
