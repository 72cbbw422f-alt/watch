import SwiftUI
import SwiftData

struct EpisodeHistoryView: View {
    @Query(sort: \EpisodeWatchEvent.watchedAt, order: .reverse)
    private var events: [EpisodeWatchEvent]
    @Query(sort: \\MovieWatchEvent.watchedAt, order: .reverse)
    private var movieEvents: [MovieWatchEvent]
    @Query private var entries: [LibraryEntry]

    private var seriesNames: [Int: String] {
        Dictionary(entries.filter { $0.mediaKind == "tv" || $0.mediaKind == "television" }.map {
            ($0.tmdbID, $0.title)
        }, uniquingKeysWith: { first, _ in first })
    }

    var body: some View {
        ZStack {
            WatchlistColor.background.ignoresSafeArea()
            if events.isEmpty && movieEvents.isEmpty {
                emptyState
            } else {
                List {
                    if !movieEvents.isEmpty {
                        Section("FILMER") {
                            ForEach(movieEvents) { event in
                                HStack(spacing: 12) {
                                    Image(systemName: "film")
                                        .foregroundStyle(WatchlistColor.accent)
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(event.title)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(WatchlistColor.primaryText)
                                        Text(event.watchedAt.formatted(date: .long, time: .shortened))
                                            .font(.system(size: 10))
                                            .foregroundStyle(WatchlistColor.mutedText)
                                    }
                                    Spacer()
                                    Text(event.sourceRawValue == "manual" ? "MANUELL" : event.sourceRawValue.uppercased())
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(WatchlistColor.accent)
                                }
                                .padding(.vertical, 6)
                                .listRowBackground(WatchlistColor.surface)
                            }
                        }
                    }
                    if !events.isEmpty {
                        Section("SERIER") {
                    ForEach(events) { event in
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(seriesNames[event.seriesID] ?? "Serie")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(WatchlistColor.primaryText)
                                Text("\(event.episodeStableID.replacingOccurrences(of: "tv-\(event.seriesID)-", with: "")) · \(event.episodeTitle)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(WatchlistColor.secondaryText)
                                    .lineLimit(2)
                                Text(event.watchedAt.formatted(date: .long, time: .shortened))
                                    .font(.system(size: 10))
                                    .foregroundStyle(WatchlistColor.mutedText)
                            }
                            Spacer()
                            Text(event.sourceRawValue == "manual" ? "MANUELL" : event.sourceRawValue.uppercased())
                                .font(.system(size: 8, weight: .bold))
                                .tracking(0.8)
                                .foregroundStyle(WatchlistColor.accent)
                        }
                        .padding(.vertical, 7)
                        .listRowBackground(WatchlistColor.surface)
                    }
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
