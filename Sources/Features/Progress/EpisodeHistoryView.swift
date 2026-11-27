import SwiftUI
import SwiftData

private struct ViewingHistoryRow: Identifiable {
    let id: String
    let date: Date
    let title: String
    let detail: String
    let symbol: String
    let source: String
}

struct EpisodeHistoryView: View {
    @Query(sort: \EpisodeWatchEvent.watchedAt, order: .reverse)
    private var events: [EpisodeWatchEvent]
    @Query(sort: \MovieWatchEvent.watchedAt, order: .reverse)
    private var movieEvents: [MovieWatchEvent]
    @Query private var entries: [LibraryEntry]

    private var seriesNames: [Int: String] {
        Dictionary(entries.filter { $0.mediaKind == "tv" || $0.mediaKind == "television" }.map {
            ($0.tmdbID, $0.title)
        }, uniquingKeysWith: { first, _ in first })
    }

    private var historyRows: [ViewingHistoryRow] {
        let episodeRows = events.map { event in
            ViewingHistoryRow(
                id: "episode-\(event.id.uuidString)",
                date: event.watchedAt,
                title: seriesNames[event.seriesID] ?? "Serie",
                detail: "S\(String(format: "%02d", event.seasonNumber))E\(String(format: "%02d", event.episodeNumber)) · \(event.episodeTitle)",
                symbol: "tv",
                source: event.sourceRawValue
            )
        }
        let filmRows = movieEvents.map { event in
            ViewingHistoryRow(
                id: "movie-\(event.id.uuidString)",
                date: event.watchedAt,
                title: event.title,
                detail: "Film",
                symbol: "film",
                source: event.sourceRawValue
            )
        }
        return (episodeRows + filmRows).sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            WatchlistColor.background.ignoresSafeArea()
            if events.isEmpty && movieEvents.isEmpty {
                emptyState
            } else {
                List {
                    Section("SENASTE VISNINGAR") {
                        ForEach(historyRows) { row in
                            HStack(spacing: 12) {
                                Image(systemName: row.symbol)
                                    .foregroundStyle(WatchlistColor.accent)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(row.title)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(WatchlistColor.primaryText)
                                    Text(row.detail)
                                        .font(.system(size: 11))
                                        .foregroundStyle(WatchlistColor.secondaryText)
                                        .lineLimit(2)
                                    Text(row.date.formatted(date: .long, time: .shortened))
                                        .font(.system(size: 10))
                                        .foregroundStyle(WatchlistColor.mutedText)
                                }
                                Spacer()
                                Text(row.source == "manual" ? "MANUELL" : row.source.uppercased())
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(WatchlistColor.accent)
                            }
                            .padding(.vertical, 6)
                            .listRowBackground(WatchlistColor.surface)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
            }
        }
        .navigationTitle("Visningshistorik")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(WatchlistColor.accent)
            Text("Ingen visningshistorik ännu")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(WatchlistColor.primaryText)
            Text("När du registrerar en film eller markerar ett avsnitt som sett sparas tillfället här. Omtittningar registreras separat.")
                .font(.system(size: 12))
                .foregroundStyle(WatchlistColor.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(36)
    }
}
