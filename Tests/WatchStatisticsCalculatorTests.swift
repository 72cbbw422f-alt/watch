import XCTest
@testable import WATCHLIST

final class WatchStatisticsCalculatorTests: XCTestCase {
    func testUniqueCountsIgnoreRepeatedViewingEvents() {
        XCTAssertEqual(
            WatchStatisticsCalculator.uniqueMovieCount([550, 550, 680, 550]),
            2
        )
        XCTAssertEqual(
            WatchStatisticsCalculator.uniqueEpisodeCount([
                "tv-1396-s1-e1",
                "tv-1396-s1-e1",
                "tv-1396-s1-e2"
            ]),
            2
        )
    }

    func testAdditionalViewingCountCountsOnlyEventsBeyondFirstView() {
        XCTAssertEqual(
            WatchStatisticsCalculator.additionalViewingCount(
                totalEvents: 8,
                uniqueEpisodes: 4,
                uniqueMovies: 2
            ),
            2
        )
    }

    func testAdditionalViewingCountNeverReturnsNegativeValue() {
        XCTAssertEqual(
            WatchStatisticsCalculator.additionalViewingCount(
                totalEvents: 2,
                uniqueEpisodes: 3,
                uniqueMovies: 1
            ),
            0
        )
    }

    func testMonthlyCountsCombineFilmAndEpisodeEvents() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let dates = [
            date("2026-01-02T10:00:00Z"),
            date("2026-01-18T10:00:00Z"),
            date("2026-03-01T10:00:00Z")
        ]
        let movieDates = [
            date("2026-01-25T10:00:00Z"),
            date("2026-12-31T10:00:00Z")
        ]

        let counts = WatchStatisticsCalculator.monthlyCounts(
            episodeDates: dates,
            movieDates: movieDates,
            calendar: calendar
        )

        XCTAssertEqual(counts.count, 12)
        XCTAssertEqual(counts[0], 3)
        XCTAssertEqual(counts[2], 1)
        XCTAssertEqual(counts[11], 1)
        XCTAssertEqual(counts.reduce(0, +), 5)
    }

    private func date(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }
}
