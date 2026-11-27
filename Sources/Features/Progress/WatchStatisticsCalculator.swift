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

    /// Returns the zero-based month index with the most events; ties favor the earliest month.
    static func mostActiveMonthIndex(_ monthlyCounts: [Int]) -> Int? {
        guard let maximum = monthlyCounts.max(), maximum > 0 else { return nil }
        return monthlyCounts.firstIndex(of: maximum)
    }

    /// Average events per month with at least one registered viewing.
    static func averagePerActiveMonth(_ monthlyCounts: [Int]) -> Double {
        let activeMonths = monthlyCounts.filter { $0 > 0 }
        guard !activeMonths.isEmpty else { return 0 }
        return Double(activeMonths.reduce(0, +)) / Double(activeMonths.count)
    }
}
