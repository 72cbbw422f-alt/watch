import SwiftUI
import SwiftData

private struct WatchSeriesStat: Identifiable {
    let id: Int
    let title: String
    let count: Int
}

struct WatchStatsView: View {
    @Query(sort: \EpisodeWatchEvent.watchedAt, order: .reverse)
    private var events: [EpisodeWatchEvent]
    @Query(sort: \\MovieWatchEvent.watchedAt, order: .reverse)
    private var movieEvents: [MovieWatchEvent]
    @Query private var entries: [LibraryEntry]
    @State private var selectedYear = Calendar.current.component(.year, from: .now)

    private let calendar = Calendar.current
    private let monthSymbols = Calendar.current.monthSymbols

    private var years: [Int] {
        Array(Set(events.map { calendar.component(.year, from: $0.watchedAt) })).sorted(by: >)
    }

    private var yearEvents: [EpisodeWatchEvent] {
        events.filter { calendar.component(.year, from: $0.watchedAt) == selectedYear }
    }

    private var yearMovieEvents: [MovieWatchEvent] {
        movieEvents.filter { calendar.component(.year, from: $0.watchedAt) == selectedYear }
    }

    private var uniqueMovies: Int {
        Set(yearMovieEvents.map(\\.tmdbID)).count
    }

    private var uniqueEpisodes: Int {
        Set(yearEvents.map(\.episodeStableID)).count
    }

    private var rewatchEvents: Int {
        max(yearEvents.count + yearMovieEvents.count - uniqueEpisodes - uniqueMovies, 0)
    }

    private var monthlyCounts: [Int] {
        (1...12).map { month in
            yearEvents.filter { calendar.component(.month, from: $0.watchedAt) == month }.count + yearMovieEvents.filter { calendar.component(.month, from: $0.watchedAt) == month }.count
        }
    }

    private var topSeries: [WatchSeriesStat] {
        let names = Dictionary(entries.map { ($0.tmdbID, $0.title) }, uniquingKeysWith: { first, _ in first })
        let grouped = Dictionary(grouping: yearEvents, by: \.seriesID)
        return grouped.map { id, values in
            WatchSeriesStat(id: id, title: names[id] ?? "Serie", count: values.count)
        }.sorted { $0.count > $1.count }.prefix(5).map { $0 }
    }

    private var topMovies: [(id: Int, title: String, count: Int)] {
        let grouped = Dictionary(grouping: yearMovieEvents, by: \.tmdbID)
        return grouped.map { id, values in
            (id: id, title: values.first?.title ?? "Film", count: values.count)
        }.sorted { $0.count > $1.count }.prefix(5).map { $0 }
    }

    private var maxMonthlyCount: Int { max(monthlyCounts.max() ?? 0, 1) }

    var body: some View {
        ZStack {
            WatchlistColor.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    if events.isEmpty && movieEvents.isEmpty {
                        emptyState
                    } else {
                        metrics
                        monthlySection
                        topSeriesSection
                        topMoviesSection
                        Text("Statistiken bygger på registrerade filmvisningar och avsnittshändelser. Varje omtittning räknas som ett eget tillfälle. Äldre progressmarkeringar utan historikhändelse räknas inte.")
                            .font(.system(size: 10))
                            .foregroundStyle(WatchlistColor.mutedText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(20)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("Årsöversikt")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !years.contains(selectedYear), let latest = years.first { selectedYear = latest }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DIN TITTARHISTORIK")
                .font(.system(size: 9, weight: .bold))
                .tracking(1.8)
                .foregroundStyle(WatchlistColor.accent)
            HStack(alignment: .center) {
                Text("Årsöversikt")
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundStyle(WatchlistColor.primaryText)
                Spacer()
                Menu {
                    ForEach(years, id: \.self) { year in
                        Button(String(year)) { selectedYear = year }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(String(selectedYear))
                        Image(systemName: "chevron.down")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(WatchlistColor.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(WatchlistColor.surface, in: Capsule())
                }
            }
        }
    }

    private var metrics: some View {
        HStack(spacing: 0) {
            metric(value: yearEvents.count + yearMovieEvents.count, label: "TILLFÄLLEN")
            Rectangle().fill(WatchlistColor.hairline).frame(width: 1, height: 36)
            metric(value: uniqueEpisodes, label: "UNIKA AVSNITT")
            Rectangle().fill(WatchlistColor.hairline).frame(width: 1, height: 36)
            metric(value: uniqueMovies, label: "UNIKA FILMER")
            Rectangle().fill(WatchlistColor.hairline).frame(width: 1, height: 36)
            metric(value: rewatchEvents, label: "OMTITTNINGAR")
        }
        .padding(.vertical, 16)
        .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 15))
    }

    private func metric(value: Int, label: String) -> some View {
        VStack(spacing: 5) {
            Text("\(value)")
                .font(.system(size: 21, weight: .semibold, design: .rounded))
                .foregroundStyle(WatchlistColor.primaryText)
            Text(label)
                .font(.system(size: 7, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(WatchlistColor.mutedText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }

    private var monthlySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("MÅNAD FÖR MÅNAD")
                .font(.system(size: 9, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(WatchlistColor.secondaryText)
            VStack(spacing: 12) {
                ForEach(1...12, id: \.self) { month in
                    HStack(spacing: 10) {
                        Text(monthSymbols[month - 1].capitalized)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(WatchlistColor.secondaryText)
                            .frame(width: 38, alignment: .leading)
                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(WatchlistColor.accent)
                                .frame(width: monthlyCounts[month - 1] == 0 ? 0 : max(5, geometry.size.width * CGFloat(monthlyCounts[month - 1]) / CGFloat(maxMonthlyCount)), height: 7)
                                .frame(maxHeight: .infinity, alignment: .center)
                        }
                        .frame(height: 12)
                        Text(String(monthlyCounts[month - 1]))
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(WatchlistColor.primaryText)
                            .monospacedDigit()
                            .frame(width: 24, alignment: .trailing)
                    }
                }
            }
            .padding(16)
            .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 15))
        }
    }

    private var topSeriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MEST SEDDA SERIER")
                .font(.system(size: 9, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(WatchlistColor.secondaryText)
            if topSeries.isEmpty {
                Text("Inga registrerade serievisningar under året.")
                    .font(.system(size: 11))
                    .foregroundStyle(WatchlistColor.mutedText)
            } else {
                VStack(spacing: 0) {
                    ForEach(topSeries) { series in
                        HStack(spacing: 12) {
                            Text(String(format: "%02d", (topSeries.firstIndex(where: { $0.id == series.id }) ?? 0) + 1))
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(WatchlistColor.accent)
                            Text(series.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(WatchlistColor.primaryText)
                                .lineLimit(1)
                            Spacer()
                            Text("\(series.count) avsnitt")
                                .font(.system(size: 10))
                                .foregroundStyle(WatchlistColor.secondaryText)
                        }
                        .padding(.vertical, 12)
                        if series.id != topSeries.last?.id {
                            Rectangle().fill(WatchlistColor.hairline).frame(height: 1)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 15))
            }
        }
    }

    private var topMoviesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MEST SEDDA FILMER")
                .font(.system(size: 9, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(WatchlistColor.secondaryText)
            if topMovies.isEmpty {
                Text("Inga registrerade filmvisningar under året.")
                    .font(.system(size: 11))
                    .foregroundStyle(WatchlistColor.mutedText)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(topMovies.enumerated()), id: \.element.id) { index, movie in
                        HStack(spacing: 12) {
                            Text(String(format: "%02d", index + 1))
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(WatchlistColor.accent)
                            Text(movie.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(WatchlistColor.primaryText)
                                .lineLimit(1)
                            Spacer()
                            Text("\(movie.count) gånger")
                                .font(.system(size: 10))
                                .foregroundStyle(WatchlistColor.secondaryText)
                        }
                        .padding(.vertical, 12)
                        if movie.id != topMovies.last?.id {
                            Rectangle().fill(WatchlistColor.hairline).frame(height: 1)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 15))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(WatchlistColor.accent)
            Text("Ingen statistik ännu")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(WatchlistColor.primaryText)
            Text("När du registrerar filmvisningar och tittade avsnitt byggs din årsöversikt upp här.")
                .font(.system(size: 12))
                .foregroundStyle(WatchlistColor.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
