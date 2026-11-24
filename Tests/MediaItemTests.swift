import XCTest
@testable import WATCHLIST

final class MediaItemTests: XCTestCase {
    func testDecodesMovieResult() throws {
        let json = """
        {
          "id": 550,
          "title": "Fight Club",
          "overview": "A movie description",
          "poster_path": "/poster.jpg",
          "backdrop_path": "/backdrop.jpg",
          "release_date": "1999-10-15",
          "vote_average": 8.4
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(MediaItem.self, from: json)

        XCTAssertEqual(item.id, 550)
        XCTAssertEqual(item.kind, .movie)
        XCTAssertEqual(item.title, "Fight Club")
        XCTAssertEqual(item.releaseDate, "1999-10-15")
        XCTAssertEqual(item.voteAverage, 8.4)
        XCTAssertEqual(item.posterURL?.absoluteString, "https://image.tmdb.org/t/p/w500/poster.jpg")
    }

    func testDecodesTelevisionResult() throws {
        let json = """
        {
          "id": 1396,
          "name": "Breaking Bad",
          "overview": "A series description",
          "first_air_date": "2008-01-20",
          "vote_average": 9.5
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(MediaItem.self, from: json)

        XCTAssertEqual(item.kind, .television)
        XCTAssertEqual(item.title, "Breaking Bad")
        XCTAssertEqual(item.releaseDate, "2008-01-20")
        XCTAssertNil(item.posterURL)
    }

    func testEncodesAndDecodesTelevisionIdentity() throws {
        let original = MediaItem(
            id: 123,
            kind: .television,
            title: "Example Series",
            overview: "Description",
            releaseDate: "2024-01-01",
            voteAverage: 7.2
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MediaItem.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func testEmptyPosterPathProducesNoURL() {
        let item = MediaItem(
            id: 1,
            kind: .movie,
            title: "No poster",
            overview: "",
            posterPath: ""
        )

        XCTAssertNil(item.posterURL)
    }
}
