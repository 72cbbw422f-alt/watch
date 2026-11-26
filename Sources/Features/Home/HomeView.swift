import SwiftUI
import SwiftData

struct HomeView: View {
    let onExplore: () -> Void
    let onCalendar: () -> Void

    @State private var selectedFilter = "För dig"
    @State private var trendingItems: [MediaItem] = []
    @State private var isLoadingTrending = false
    @State private var trendingError: String?
    @Query(sort: \LibraryEntry.dateUpdated, order: .reverse) private var libraryEntries: [LibraryEntry]

    private var inProgressEntries: [LibraryEntry] { libraryEntries.filter { $0.status == .watching } }

    private var visibleTrendingItems: [MediaItem] {
        switch selectedFilter {
        case "Filmer": trendingItems.filter { $0.kind == .movie }
        case "Serier": trendingItems.filter { $0.kind == .television }
        default: trendingItems
        }
    }

    private let filters = ["För dig", "Filmer", "Serier"]

    var body: some View {
        ZStack {
            WatchlistColor.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 30) {
                    header
                    featured
                    quickFilters
                    continueWatching
                    recommendations
                    trending
                    premieres
                    comingSoon
                }
                .padding(.top, 10)
                .padding(.bottom, 34)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: MediaItem.self) { item in
            MediaDetailView(item: item)
        }
        .task {
            await loadTrending()
            await loadPersonalRecommendations()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("DIN PERSONLIGA BIOGRAF")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(2.1)
                    .foregroundStyle(WatchlistColor.accent)
                Text("WATCHLIST")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .tracking(-1.1)
                    .foregroundStyle(WatchlistColor.primaryText)
            }

            Spacer()

            Button(action: onExplore) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(WatchlistColor.primaryText)
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.055), in: Circle())
                    .overlay(Circle().stroke(WatchlistColor.hairline, lineWidth: 1))
            }
            .accessibilityLabel("Sök")

        }
        .padding(.horizontal, 20)
    }

    private var featured: some View {
        VStack(alignment: .leading, spacing: 18) {
            Rectangle()
                .fill(WatchlistColor.hairline)
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 11) {
                Text("ETT BIBLIOTEK FÖR BERÄTTELSER")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.7)
                    .foregroundStyle(WatchlistColor.accent)

                Text("Hitta något\nminnesvärt.")
                    .font(.system(size: 36, weight: .regular, design: .serif))
                    .tracking(-0.8)
                    .foregroundStyle(WatchlistColor.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Upptäck filmer och serier. Samla favoriterna och håll koll på vad du vill se härnäst.")
                    .font(.system(size: 13))
                    .foregroundStyle(WatchlistColor.secondaryText)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: onExplore) {
                    HStack(spacing: 8) {
                        Text("Utforska biblioteket")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(WatchlistColor.primaryText)
                    .padding(.top, 3)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)

            Rectangle()
                .fill(WatchlistColor.hairline)
                .frame(height: 1)
        }
        .padding(.horizontal, 20)
    }

    private var quickFilters: some View {
        HStack(spacing: 9) {
            ForEach(filters, id: \.self) { filter in
                Button {
                    withAnimation(.snappy(duration: 0.22)) { selectedFilter = filter }
                } label: {
                    Text(filter)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(selectedFilter == filter ? WatchlistColor.primaryText : WatchlistColor.secondaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background {
                            Capsule().fill(selectedFilter == filter ? WatchlistColor.surfaceElevated : WatchlistColor.surface)
                        }
                        .overlay(Capsule().stroke(selectedFilter == filter ? WatchlistColor.accent.opacity(0.45) : WatchlistColor.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
    }

    private var continueWatching: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeading("Fortsätt titta", eyebrow: "DIN RESA", trailing: "\(inProgressEntries.count) PÅGÅR")
            if inProgressEntries.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "play.circle")
                        .font(.system(size: 21, weight: .light))
                        .foregroundStyle(WatchlistColor.accent)
                        .frame(width: 44, height: 44)
                        .background(WatchlistColor.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Din tittarlista är redo")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(WatchlistColor.primaryText)
                        Text("Markera en titel som pågående i biblioteket så dyker den upp här.")
                            .font(.system(size: 10))
                            .foregroundStyle(WatchlistColor.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(WatchlistColor.hairline, lineWidth: 1))
            } else {
                VStack(spacing: 10) {
                    ForEach(inProgressEntries.prefix(3)) { entry in
                        NavigationLink(value: entry.mediaItem) {
                            HStack(spacing: 12) {
                                LibraryHomePoster(entry: entry)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(entry.title)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(WatchlistColor.primaryText)
                                        .lineLimit(1)
                                    Text(entry.mediaKind == "movie" ? "FILM" : "SERIE")
                                        .font(.system(size: 8, weight: .bold))
                                        .tracking(1)
                                        .foregroundStyle(WatchlistColor.mutedText)
                                    Label("Tittar på", systemImage: "play.circle.fill")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(WatchlistColor.accent)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(WatchlistColor.mutedText)
                            }
                            .padding(10)
                            .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 15))
                            .overlay(RoundedRectangle(cornerRadius: 15).stroke(WatchlistColor.hairline, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var recommendations: some View {
        Group {
            if isLoadingRecommendations || !personalRecommendations.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    sectionHeading("Utvalt för dig", eyebrow: "BYGGT FRÅN DITT BIBLIOTEK", trailing: "Personligt")
                    if isLoadingRecommendations && personalRecommendations.isEmpty {
                        ProgressView()
                            .tint(WatchlistColor.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 22)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 13) {
                                ForEach(personalRecommendations, id: \\.stableID) { item in
                                    NavigationLink(value: item) {
                                        MediaPosterTile(item: item, rank: (personalRecommendations.firstIndex(of: item) ?? 0) + 1)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
            }
        }
    }

    @MainActor
    private func loadPersonalRecommendations() async {
        guard TMDBConfiguration.isConfigured else { return }
        let seeds = libraryEntries
            .filter { $0.isFavorite || ($0.personalRating ?? 0) >= 8 }
            .sorted {
                let firstScore = ($0.isFavorite ? 100 : 0) + ($0.personalRating ?? 0)
                let secondScore = ($1.isFavorite ? 100 : 0) + ($1.personalRating ?? 0)
                if firstScore != secondScore { return firstScore > secondScore }
                return $0.dateUpdated > $1.dateUpdated
            }
            .prefix(3)

        guard !seeds.isEmpty else { return }
        isLoadingRecommendations = true
        defer { isLoadingRecommendations = false }

        let client = TMDBConfiguration.makeClient()
        let savedIDs = Set(libraryEntries.map(\\.stableID))
        var candidates: [String: MediaItem] = [:]
        for seed in seeds {
            do {
                let similar = try await client.similarTitles(to: seed.mediaItem)
                for item in similar where !savedIDs.contains(item.stableID) && item.id > 0 {
                    candidates[item.stableID] = item
                }
            } catch {
                continue
            }
        }
        personalRecommendations = candidates.values.sorted {
            if $0.voteAverage != $1.voteAverage { return $0.voteAverage > $1.voteAverage }
            return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }.prefix(12).map { $0 }
    }

    private var trending: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeading("Populärt just nu", eyebrow: "TRENDAR GLOBALT", trailing: "Upptäck")
            if isLoadingTrending && trendingItems.isEmpty {
                ProgressView()
                    .tint(WatchlistColor.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
            } else if let trendingError, trendingItems.isEmpty {
                Text(trendingError)
                    .font(.system(size: 11))
                    .foregroundStyle(WatchlistColor.secondaryText)
                    .padding(.horizontal, 20)
            } else if trendingItems.isEmpty {
                Text(TMDBConfiguration.isConfigured
                     ? "Just nu finns inget att visa. Försök igen om en stund."
                     : "Lägg till din TMDB-token för att visa veckans populäraste filmer och serier.")
                    .font(.system(size: 11))
                    .foregroundStyle(WatchlistColor.secondaryText)
                    .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 13) {
                        ForEach(visibleTrendingItems.prefix(12), id: \.stableID) { item in
                            NavigationLink(value: item) {
                                MediaPosterTile(item: item, rank: (visibleTrendingItems.firstIndex(of: item) ?? 0) + 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    @MainActor
    private func loadTrending() async {
        guard TMDBConfiguration.isConfigured else { return }
        isLoadingTrending = true
        trendingError = nil
        defer { isLoadingTrending = false }

        do {
            trendingItems = try await TMDBConfiguration.makeClient().trendingThisWeek()
        } catch {
            trendingError = error.localizedDescription
        }
    }

    private var premieres: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("KOMMER SNART")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(WatchlistColor.accent)
                    Text("Premiärkalender")
                        .font(.system(size: 19, weight: .semibold, design: .serif))
                        .foregroundStyle(WatchlistColor.primaryText)
                }
                Spacer()
                Button(action: onCalendar) {
                    HStack(spacing: 5) {
                        Text("Visa alla")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WatchlistColor.accent)
                }
                .buttonStyle(.plain)
            }
            Button(action: onCalendar) {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(WatchlistColor.accent)
                        .frame(width: 42, height: 42)
                        .background(WatchlistColor.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Kommande film- och seriepremiärer")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(WatchlistColor.primaryText)
                            .multilineTextAlignment(.leading)
                        Text("Se svenska premiärdatum i kalendern.")
                            .font(.system(size: 10))
                            .foregroundStyle(WatchlistColor.secondaryText)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(WatchlistColor.mutedText)
                }
                .padding(14)
                .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(WatchlistColor.hairline, lineWidth: 1))
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    private var comingSoon: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeading("Din lista", eyebrow: "SPARAT FÖR SENARE", trailing: "Bibliotek")
            HStack(spacing: 12) {
                Image(systemName: "bookmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(WatchlistColor.accent)
                    .frame(width: 38, height: 38)
                    .background(WatchlistColor.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Dina favoriter, samlade")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(WatchlistColor.primaryText)
                    Text("Spara filmer och serier du vill se senare.")
                        .font(.system(size: 11))
                        .foregroundStyle(WatchlistColor.secondaryText)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WatchlistColor.mutedText)
            }
            .padding(14)
            .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(WatchlistColor.hairline, lineWidth: 1))
        }
        .padding(.horizontal, 20)
    }

    private func sectionHeading(_ title: String, eyebrow: String, trailing: String) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 5) {
                Text(eyebrow)
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.8)
                    .foregroundStyle(WatchlistColor.accent)
                Text(title)
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .tracking(-0.55)
                    .foregroundStyle(WatchlistColor.primaryText)
            }
            Spacer()
            Text(trailing)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(WatchlistColor.secondaryText)
        }
        .padding(.horizontal, 20)
    }
}


private struct LibraryHomePoster: View {
    let entry: LibraryEntry

    var body: some View {
        Group {
            if let url = entry.mediaItem.posterURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: 48, height: 66)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(WatchlistColor.surfaceElevated)
            .overlay {
                Image(systemName: entry.mediaKind == "movie" ? "film" : "tv")
                    .foregroundStyle(WatchlistColor.mutedText)
            }
    }
}

private struct MediaPosterTile: View {
    let item: MediaItem
    let rank: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                posterArtwork
                LinearGradient(colors: [.clear, .black.opacity(0.78)], startPoint: .center, endPoint: .bottom)
                Text(String(format: "%02d", rank))
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(11)
            }
            .frame(width: 132, height: 184)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(.white.opacity(0.10), lineWidth: 1))

            Text(item.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(WatchlistColor.primaryText)
                .lineLimit(1)
            HStack(spacing: 5) {
                Text(item.kind.displayName.uppercased())
                if item.voteAverage > 0 {
                    Text("·")
                    Image(systemName: "star.fill")
                        .foregroundStyle(WatchlistColor.accent)
                    Text(String(format: "%.1f", item.voteAverage))
                }
            }
            .font(.system(size: 8, weight: .bold))
            .tracking(0.5)
            .foregroundStyle(WatchlistColor.mutedText)
            .lineLimit(1)
        }
        .frame(width: 132, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var posterArtwork: some View {
        if let url = item.posterURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .empty:
                    placeholder.overlay { ProgressView().tint(.white.opacity(0.7)) }
                case .failure:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
            .frame(width: 132, height: 184)
            .clipped()
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(WatchlistColor.surfaceElevated.gradient)
            .overlay {
                Image(systemName: item.kind == .movie ? "film" : "tv")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(WatchlistColor.mutedText)
            }
            .frame(width: 132, height: 184)
    }
}

private struct PremiereRow: View {
    let day: String
    let month: String
    let title: String
    let detail: String
    let kind: String

    var body: some View {
        HStack(spacing: 13) {
            VStack(spacing: 2) {
                Text(month)
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(WatchlistColor.accent)
                Text(day)
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(WatchlistColor.primaryText)
            }
            .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WatchlistColor.primaryText)
                Text(detail)
                    .font(.system(size: 10))
                    .foregroundStyle(WatchlistColor.secondaryText)
            }

            Spacer(minLength: 4)

            Text(kind)
                .font(.system(size: 8, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(WatchlistColor.warmHighlight)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(WatchlistColor.warmHighlight.opacity(0.10), in: Capsule())
        }
        .padding(.vertical, 14)
    }
}
