import Foundation

/// Pure calculations for the annual viewing dashboard.
enum WatchStatisticsCalculator {
    static func uniqueMovieCount(_ movieIDs: [Int]) -> Int {
        Set(movieIDs).count
    }

    static func uniqueEpisodeCount(_ episodeIDs: [String]) -> Int {
        Set(episodeIDs).count
    }

    /// Counts viewing events beyond the first event for each distinct title/episode.
    static func additionalViewingCount(
        totalEvents: Int,
        uniqueEpisodes: Int,
        uniqueMovies: Int
    ) -> Int {
        max(totalEvents - uniqueEpisodes - uniqueMovies, 0)
    }

    /// Returns one count for each calendar month, January through December.
    static func monthlyCounts(
        episodeDates: [Date],
        movieDates: [Date],
        calendar: Calendar
    ) -> [Int] {
        var counts = Array(repeating: 0, count: 12)
        for date in episodeDates + movieDates {
            let month = calendar.component(.month, from: date)
            guard (1...12).contains(month) else { continue }
            counts[month - 1] += 1
        }
        return counts
    }
}
