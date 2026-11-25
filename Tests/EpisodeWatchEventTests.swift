import XCTest
import SwiftData
@testable import WATCHLIST

final class EpisodeWatchEventTests: XCTestCase {
    private func makeEpisode() throws -> TVEpisode {
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
        return try JSONDecoder().decode(TVEpisode.self, from: json)
    }

    func testMultipleViewsOfSameEpisodeRemainSeparateEvents() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: EpisodeWatchEvent.self,
            configurations: configuration
        )
        let context = ModelContext(container)
        let episode = try makeEpisode()
        let firstView = Date(timeIntervalSince1970: 1_700_000_000)
        let secondView = Date(timeIntervalSince1970: 1_710_000_000)

        context.insert(EpisodeWatchEvent(
            seriesID: 1396,
            episode: episode,
            watchedAt: firstView
        ))
        context.insert(EpisodeWatchEvent(
            seriesID: 1396,
            episode: episode,
            watchedAt: secondView
        ))
        try context.save()

        let events = try context.fetch(FetchDescriptor<EpisodeWatchEvent>())
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(Set(events.map(\.episodeStableID)).count, 1)
        XCTAssertEqual(Set(events.map(\.id)).count, 2)
        XCTAssertEqual(Set(events.map(\.watchedAt)), Set([firstView, secondView]))
        XCTAssertTrue(events.allSatisfy { $0.sourceRawValue == "manual" })
    }

    func testEventKeepsSeriesEpisodeIdentityAndTitle() throws {
        let episode = try makeEpisode()
        let event = EpisodeWatchEvent(seriesID: 1396, episode: episode)

        XCTAssertEqual(event.seriesID, 1396)
        XCTAssertEqual(event.episodeID, 62085)
        XCTAssertEqual(event.seasonNumber, 1)
        XCTAssertEqual(event.episodeNumber, 1)
        XCTAssertEqual(event.episodeTitle, "Pilot")
        XCTAssertEqual(event.episodeStableID, "tv-1396-s1-e1")
    }
}
