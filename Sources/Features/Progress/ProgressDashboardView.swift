import SwiftUI
import SwiftData

struct ProgressDashboardView: View {
    @Query(sort: \LibraryEntry.dateUpdated, order: .reverse) private var entries: [LibraryEntry]
    @Query private var episodeProgress: [EpisodeProgress]
    @State private var selectedFilter = ProgressFilter.watching
    @State private var searchText = ""

    private var seriesEntries: [LibraryEntry] {
        entries.filter { $0.mediaKind == "tv" || $0.mediaKind == "television" }
    }

    private var filteredEntries: [LibraryEntry] {
        seriesEntries.filter { entry in
            let matchesFilter: Bool
            switch selectedFilter {
            case .watching: matchesFilter = entry.status == .watching
            case .planned: matchesFilter = entry.status == .wantToWatch
            case .watched: matchesFilter = entry.status == .watched
            }
            return matchesFilter && (searchText.isEmpty || entry.title.localizedCaseInsensitiveContains(searchText))
        }
    }

    private var watchedEpisodeCount: Int {
        episodeProgress.filter(\.isWatched).count
    }

    var body: some View {
        ZStack {
            WatchlistColor.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    summary
                    filterBar
                    if filteredEntries.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 17) {
                            ForEach(filteredEntries) { entry in
                                NavigationLink(value: entry.mediaItem) {
                                    ProgressSeriesRow(
                                        entry: entry,
                                        watchedCount: episodeProgress.filter { $0.seriesID == entry.tmdbID && $0.isWatched }.count
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 22)
                .padding(.bottom, 40)
            }
        }
        .searchable(text: $searchText, prompt: "Sök bland dina serier")
        .navigationDestination(for: MediaItem.self) { item in
            MediaDetailView(item: item)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("DIN TITTNING")
                .font(.system(size: 9, weight: .bold))
                .tracking(2)
                .foregroundStyle(WatchlistColor.accent)
            Text("Progress")
                .font(.system(size: 31, weight: .bold, design: .rounded))
                .tracking(-0.8)
                .foregroundStyle(WatchlistColor.primaryText)
            Text("\(seriesEntries.count) serier i biblioteket")
                .font(.system(size: 12))
                .foregroundStyle(WatchlistColor.secondaryText)
        }
        .padding(.horizontal, 20)
    }

    private var summary: some View {
        HStack(spacing: 0) {
            metric(value: seriesEntries.filter { $0.status == .watching }.count, label: "PÅGÅR")
            Rectangle().fill(WatchlistColor.hairline).frame(width: 1, height: 34)
            metric(value: watchedEpisodeCount, label: "SEDDA AVSNITT")
            Rectangle().fill(WatchlistColor.hairline).frame(width: 1, height: 34)
            metric(value: seriesEntries.filter { $0.status == .wantToWatch }.count, label: "PLANERADE")
        }
        .padding(.vertical, 15)
        .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 15))
        .padding(.horizontal, 20)
    }

    private func metric(value: Int, label: String) -> some View {
        VStack(spacing: 5) {
            Text("\(value)")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(WatchlistColor.primaryText)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .tracking(0.7)
                .foregroundStyle(WatchlistColor.mutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ProgressFilter.allCases) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        HStack(spacing: 6) {
                            Text(filter.title)
                            Text("\(count(for: filter))")
                                .foregroundStyle(selectedFilter == filter ? WatchlistColor.primaryText.opacity(0.75) : WatchlistColor.mutedText)
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(selectedFilter == filter ? WatchlistColor.primaryText : WatchlistColor.secondaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(selectedFilter == filter ? WatchlistColor.surfaceElevated : Color.clear, in: Capsule())
                        .overlay(Capsule().stroke(selectedFilter == filter ? WatchlistColor.accent.opacity(0.45) : WatchlistColor.hairline, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func count(for filter: ProgressFilter) -> Int {
        seriesEntries.filter {
            switch filter {
            case .watching: $0.status == .watching
            case .planned: $0.status == .wantToWatch
            case .watched: $0.status == .watched
            }
        }.count
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "play.rectangle")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(WatchlistColor.accent)
            Text("Inga serier här ännu")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(WatchlistColor.primaryText)
            Text("Serier du lägger till i biblioteket visas här med sin avsnittsprogress.")
                .font(.system(size: 12))
                .foregroundStyle(WatchlistColor.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
        .padding(.vertical, 60)
    }
}

private enum ProgressFilter: String, CaseIterable, Identifiable {
    case watching, planned, watched
    var id: String { rawValue }
    var title: String {
        switch self {
        case .watching: "Pågår"
        case .planned: "Planerade"
        case .watched: "Avslutade"
        }
    }
}

private struct ProgressSeriesRow: View {
    let entry: LibraryEntry
    let watchedCount: Int

    private var total: Int? { entry.episodeTotalCount }

    private static var todayISODate: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: .now)
    }
    private var fraction: Double {
        guard let total, total > 0 else { return 0 }
        return min(Double(watchedCount) / Double(total), 1)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            poster
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(WatchlistColor.primaryText)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(entry.status.title.uppercased())
                    if let year = entry.releaseDate?.prefix(4), !year.isEmpty {
                        Text("·")
                        Text(String(year))
                    }
                }
                .font(.system(size: 8, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(WatchlistColor.mutedText)

                if let total, total > 0 {
                    ProgressView(value: fraction)
                        .tint(WatchlistColor.accent)
                        .background(WatchlistColor.surfaceElevated)
                    Text("\(watchedCount) av \(total) avsnitt · \(Int(fraction * 100)) %")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(WatchlistColor.secondaryText)
                } else {
                    Text(watchedCount == 0 ? "Ingen avsnittsprogress registrerad" : "\(watchedCount) avsnitt markerade som sedda")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(WatchlistColor.secondaryText)
                }
                if let nextCode = entry.nextEpisodeCode {
                    HStack(spacing: 5) {
                        Image(systemName: "play.fill").foregroundStyle(WatchlistColor.accent)
                        Text("Nästa: \(nextCode)").foregroundStyle(WatchlistColor.primaryText)
                        if let date = entry.nextEpisodeAirDate, !date.isEmpty {
                            Text("· \(date)").foregroundStyle(WatchlistColor.mutedText)
                            Text(date <= Self.todayISODate ? "NYTT AVSNITT" : "IKAPP")
                                .foregroundStyle(date <= Self.todayISODate ? WatchlistColor.accent : WatchlistColor.mutedText)
                        }
                    }
                    .font(.system(size: 9, weight: .semibold))
                    .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(WatchlistColor.mutedText)
                .padding(.top, 4)
        }
        .padding(.vertical, 5)
    }

    private var poster: some View {
        Group {
            if let url = entry.mediaItem.posterURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image { image.resizable().scaledToFill() }
                    else { placeholder }
                }
            } else {
                placeholder
            }
        }
        .frame(width: 78, height: 112)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(WatchlistColor.surfaceElevated)
            .overlay(Image(systemName: "tv").foregroundStyle(WatchlistColor.mutedText))
    }
}
