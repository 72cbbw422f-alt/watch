import XCTest
import SwiftData
@testable import WATCHLIST

final class EpisodeProgressTests: XCTestCase {
    private func makeEpisode() throws -> TVEpisode {
        let json = """
        {
          "id": 101,
          "name": "Pilot",
          "overview": "The beginning",
          "episode_number": 1,
          "season_number": 2,
          "air_date": "2026-01-10",
          "runtime": 48,
          "still_path": null,
          "vote_average": 8.5
        }
        """
        return try JSONDecoder().decode(TVEpisode.self, from: Data(json.utf8))
    }

    func testStableIDUsesSeriesSeasonAndEpisodeNumbers() {
        XCTAssertEqual(
            EpisodeProgress.makeStableID(seriesID: 1396, seasonNumber: 2, episodeNumber: 1),
            "tv-1396-s2-e1"
        )
    }

    func testWatchedStateCanBeToggled() throws {
        let progress = EpisodeProgress(seriesID: 1396, episode: try makeEpisode())

        XCTAssertFalse(progress.isWatched)
        progress.setWatched(true)
        XCTAssertTrue(progress.isWatched)
        progress.setWatched(false)
        XCTAssertFalse(progress.isWatched)
    }

    func testEpisodeProgressPersistsInMemory() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: EpisodeProgress.self,
            configurations: configuration
        )
        let context = ModelContext(container)
        let progress = EpisodeProgress(seriesID: 1396, episode: try makeEpisode(), isWatched: true)

        context.insert(progress)
        try context.save()

        let saved = try context.fetch(FetchDescriptor<EpisodeProgress>())
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.stableID, "tv-1396-s2-e1")
        XCTAssertTrue(saved.first?.isWatched == true)
    }
}
