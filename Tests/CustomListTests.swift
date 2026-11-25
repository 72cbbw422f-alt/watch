import XCTest
import SwiftData
@testable import WATCHLIST

final class CustomListTests: XCTestCase {
    private func makeItem(id: Int, kind: MediaKind) -> MediaItem {
        MediaItem(
            id: id,
            kind: kind,
            title: kind == .movie ? "Film \(id)" : "Serie \(id)",
            overview: "Beskrivning",
            posterPath: "/poster.jpg",
            backdropPath: nil,
            releaseDate: "2026-01-01",
            voteAverage: 7.5
        )
    }

    func testListTrimsNameAndCreatesStableIdentifier() {
        let list = CustomList(name: "  Favoriter  ")

        XCTAssertEqual(list.name, "Favoriter")
        XCTAssertFalse(list.id.isEmpty)
    }

    func testSameTitleCanBelongToMultipleLists() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: CustomList.self, CustomListItem.self,
            configurations: configuration
        )
        let context = ModelContext(container)
        let first = CustomList(name: "Favoriter")
        let second = CustomList(name: "Helg")
        let movie = makeItem(id: 550, kind: .movie)

        context.insert(first)
        context.insert(second)
        context.insert(CustomListItem(listID: first.id, item: movie))
        context.insert(CustomListItem(listID: second.id, item: movie))
        try context.save()

        let saved = try context.fetch(FetchDescriptor<CustomListItem>())
        XCTAssertEqual(saved.count, 2)
        XCTAssertEqual(Set(saved.map(\.listID)), Set([first.id, second.id]))
        XCTAssertEqual(Set(saved.map(\.mediaStableID)), [movie.stableID])
    }

    func testMembershipPreventsDuplicateIdentityWithinSameList() {
        let list = CustomList(name: "Thrillers")
        let movie = makeItem(id: 550, kind: .movie)
        let first = CustomListItem(listID: list.id, item: movie)
        let duplicate = CustomListItem(listID: list.id, item: movie)

        XCTAssertEqual(first.stableID, duplicate.stableID)
        XCTAssertEqual(first.mediaItem, movie)
    }

    func testMembershipRoundTripsTelevisionMetadata() {
        let list = CustomList(name: "Serier")
        let series = makeItem(id: 1396, kind: .television)
        let membership = CustomListItem(listID: list.id, item: series)

        XCTAssertEqual(membership.mediaItem, series)
        XCTAssertEqual(membership.mediaKind, MediaKind.television.rawValue)
    }
}
