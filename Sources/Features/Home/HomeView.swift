import SwiftUI
import SwiftData

struct HomeView: View {
    let onExplore: () -> Void
    let onCalendar: () -> Void

    @State private var selectedFilter = "För dig"
    @State private var trendingItems: [MediaItem] = []
    @State private var hiddenGemItems: [MediaItem] = []
    @State private var isLoadingTrending = false
    @State private var trendingError: String?
    @State private var personalRecommendations: [MediaItem] = []
    @State private var isLoadingRecommendations = false
    @State private var recommendationRequestID = UUID()
    @State private var homeUpNextItems: [HomeUpNextItem] = []
    @State private var isLoadingHomeUpNext = false
    @State private var homeUpNextRequestID = UUID()
    @Query(sort: \LibraryEntry.dateUpdated, order: .reverse) private var libraryEntries: [LibraryEntry]
    @Query private var episodeProgressEntries: [EpisodeProgress]

    private var inProgressEntries: [LibraryEntry] { libraryEntries.filter { $0.status == .watching } }

    private var followedSeries: [LibraryEntry] {
        libraryEntries.filter { $0.mediaKind == MediaKind.television.rawValue && $0.status != .watched }
    }

    private var upNextSeedKey: String {
        followedSeries.map(\.stableID).sorted().joined(separator: "|") + "#" +
        episodeProgressEntries.map { "\($0.stableID):\($0.isWatched)" }.sorted().joined(separator: "|")
    }

    private var recommendationSeedKey: String {
        libraryEntries
            .filter { $0.isFavorite || ($0.personalRating ?? 0) >= 8 }
            .sorted {
                let firstScore = ($0.isFavorite ? 100 : 0) + ($0.personalRating ?? 0)
                let secondScore = ($1.isFavorite ? 100 : 0) + ($1.personalRating ?? 0)
                if firstScore != secondScore { return firstScore > secondScore }
                return $0.dateUpdated > $1.dateUpdated
            }
            .prefix(3)
            .map { "\($0.stableID):\($0.isFavorite):\($0.personalRating ?? 0):\($0.dateUpdated.timeIntervalSince1970)" }
            .joined(separator: "|")
        + "#saved:"
        + libraryEntries.map(\.stableID).sorted().joined(separator: "|")
    }

    private var visibleTrendingItems: [MediaItem] {
        switch selectedFilter {
        case "Filmer": trendingItems.filter { $0.kind == .movie }
        case "Serier": trendingItems.filter { $0.kind == .television }
        default: trendingItems
        }
    }

    private let filters = ["För dig", "Filmer", "Serier"]

    private var savedStableIDs: Set<String> { Set(libraryEntries.map(\.stableID)) }

    private var tonightItems: [MediaItem] {
        let candidates = personalRecommendations + trendingItems
        var seen = Set<String>()
        return candidates.filter {
            seen.insert($0.stableID).inserted && !savedStableIDs.contains($0.stableID)
        }.prefix(10).map { $0 }
    }

    private var hiddenGems: [MediaItem] {
        let trendingIDs = Set(trendingItems.map(\.stableID))
        return hiddenGemItems
            .filter { !savedStableIDs.contains($0.stableID) && !trendingIDs.contains($0.stableID) }
            .prefix(10)
            .map { $0 }
    }

    private var watchlistMix: [MediaItem] {
        // Keep this carousel distinct from the immediately preceding "Ikväll kanske?" section.
        var seen = Set(tonightItems.map(\.stableID))
        return (hiddenGems + personalRecommendations + trendingItems).filter {
            seen.insert($0.stableID).inserted && !savedStableIDs.contains($0.stableID)
        }.prefix(12).map { $0 }
    }

    var body: some View {
        ZStack {
            WatchlistColor.background.ignoresSafeArea()

            GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 30) {
                        header
                        featured
                        quickFilters
                        homeUpNext
                        tonightPicks
                        continueWatching
                        watchlistMixSection
                        hiddenGemsSection
                        trending
                        premieres
                        comingSoon
                    }
                    .frame(width: geometry.size.width, alignment: .leading)
                    .padding(.top, 10)
                    .padding(.bottom, 34)
                }
                .frame(width: geometry.size.width, alignment: .leading)
                .scrollClipDisabled(false)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: MediaItem.self) { item in
            MediaDetailView(item: item)
        }
        .task {
            await loadTrending()
        }
        .task(id: recommendationSeedKey) {
            await loadPersonalRecommendations()
        }
        .task(id: upNextSeedKey) {
            await loadHomeUpNext()
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
        Group {
            if let item = trendingItems.first {
                NavigationLink(value: item) {
                    ZStack(alignment: .bottomLeading) {
                        Rectangle()
                            .fill(WatchlistColor.surfaceElevated)
                        if let url = item.backdropURL {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image.resizable().scaledToFill()
                                } else {
                                    heroFallback
                                }
                            }
                        } else {
                            heroFallback
                        }
                        LinearGradient(
                            stops: [
                                .init(color: .black.opacity(0.02), location: 0),
                                .init(color: .black.opacity(0.18), location: 0.38),
                                .init(color: .black.opacity(0.88), location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        VStack(alignment: .leading, spacing: 9) {
                            Text("VECKANS UTVALDA")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1.8)
                                .foregroundStyle(WatchlistColor.accent)
                            Text(item.title)
                                .font(.system(size: 27, weight: .semibold, design: .serif))
                                .tracking(-0.5)
                                .foregroundStyle(.white)
                                .lineLimit(2)
                            HStack(spacing: 10) {
                                Text(item.kind.displayName.uppercased())
                                if let year = item.releaseDate?.prefix(4), !year.isEmpty {
                                    Text("·")
                                    Text(String(year))
                                }
                                if item.voteAverage > 0 {
                                    Label(String(format: "%.1f", item.voteAverage), systemImage: "star.fill")
                                }
                            }
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.82))
                            Label("Visa titel", systemImage: "arrow.up.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(WatchlistColor.accent)
                                .padding(.top, 2)
                        }
                        .padding(20)
                    }
                    .frame(height: 265)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(WatchlistColor.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("ETT BIBLIOTEK FÖR BERÄTTELSER")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1.7)
                        .foregroundStyle(WatchlistColor.accent)
                    Text("Hitta något\nminnesvärt.")
                        .font(.system(size: 35, weight: .regular, design: .serif))
                        .tracking(-0.8)
                        .foregroundStyle(WatchlistColor.primaryText)
                    Text("Upptäck filmer och serier. Samla favoriterna och håll koll på vad du vill se härnäst.")
                        .font(.system(size: 13))
                        .foregroundStyle(WatchlistColor.secondaryText)
                        .lineSpacing(4)
                    Button(action: onExplore) {
                        Label("Utforska biblioteket", systemImage: "arrow.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(WatchlistColor.accent)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 8)
            }
        }
        .padding(.horizontal, 20)
    }

    private var heroFallback: some View {
        LinearGradient(
            colors: [WatchlistColor.surfaceElevated, WatchlistColor.backgroundElevated],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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

    private var homeUpNext: some View {
        Group {
            if !followedSeries.isEmpty {
                VStack(alignment: .leading, spacing: 13) {
                    sectionHeading("Up Next", eyebrow: "NÄSTA AVSNITT I DINA SERIER", trailing: "\(homeUpNextItems.count) KOMMANDE")
                    if isLoadingHomeUpNext && homeUpNextItems.isEmpty {
                        ProgressView()
                            .tint(WatchlistColor.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                    } else if homeUpNextItems.isEmpty {
                        HStack(spacing: 10) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(WatchlistColor.accent)
                            Text("Inga nya avsnitt är schemalagda just nu. Vi håller koll på dina serier.")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(WatchlistColor.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .padding(14)
                        .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(WatchlistColor.hairline, lineWidth: 1))
                        .padding(.horizontal, 20)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 10) {
                                ForEach(homeUpNextItems) { upcoming in
                                    NavigationLink(value: upcoming.series) {
                                        HStack(spacing: 10) {
                                            LibraryHomePoster(entry: upcoming.entry)
                                                .frame(width: 48, height: 66)
                                            VStack(alignment: .leading, spacing: 5) {
                                                Text(upcoming.entry.title)
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundStyle(WatchlistColor.primaryText)
                                                    .lineLimit(1)
                                                Text(upcoming.episode.displayCode)
                                                    .font(.system(size: 9, weight: .bold))
                                                    .tracking(0.6)
                                                    .foregroundStyle(WatchlistColor.accent)
                                                Text(upcoming.episode.name)
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundStyle(WatchlistColor.secondaryText)
                                                    .lineLimit(2)
                                                Text(upcoming.airDate.formatted(.dateTime.locale(Locale(identifier: "sv_SE")).weekday(.wide).day().month(.abbreviated)).capitalized)
                                                    .font(.system(size: 9, weight: .semibold))
                                                    .foregroundStyle(WatchlistColor.accent)
                                                    .lineLimit(1)
                                            }
                                            Spacer(minLength: 0)
                                        }
                                        .padding(10)
                                        .frame(width: 225, height: 88, alignment: .leading)
                                        .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(WatchlistColor.hairline, lineWidth: 1))
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
    private func loadHomeUpNext() async {
        let series = followedSeries
        guard TMDBConfiguration.isConfigured, !series.isEmpty else {
            homeUpNextItems = []
            isLoadingHomeUpNext = false
            return
        }

        let requestID = UUID()
        homeUpNextRequestID = requestID
        isLoadingHomeUpNext = true
        defer {
            if homeUpNextRequestID == requestID {
                isLoadingHomeUpNext = false
            }
        }
        let client = TMDBConfiguration.makeClient()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var upcoming: [HomeUpNextItem] = []

        for entry in series.prefix(40) {
            guard !Task.isCancelled else { return }
            do {
                let details = try await client.televisionDetails(id: entry.tmdbID)
                guard let last = details.lastEpisodeToAir,
                      let next = details.nextEpisodeToAir,
                      let date = homePremiereDate(from: next.airDate),
                      date >= today,
                      episodeProgressEntries.contains(where: {
                          $0.seriesID == entry.tmdbID &&
                          $0.seasonNumber == last.seasonNumber &&
                          $0.episodeNumber == last.episodeNumber &&
                          $0.isWatched
                      }) else { continue }

                upcoming.append(HomeUpNextItem(
                    entry: entry,
                    series: entry.mediaItem,
                    episode: next,
                    airDate: date
                ))
            } catch {
                // A single unavailable series must not prevent the rest from loading.
                continue
            }
        }

        guard !Task.isCancelled, homeUpNextRequestID == requestID else { return }
        homeUpNextItems = upcoming.sorted { $0.airDate < $1.airDate }
    }

    private func homePremiereDate(from value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
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


    private var tonightPicks: some View {
        posterCarousel(
            title: "Ikväll kanske?",
            eyebrow: "NÅGOT ATT SE",
            trailing: "För dig",
            items: tonightItems
        )
    }

    private var watchlistMixSection: some View {
        posterCarousel(
            title: "Watchlist Mix",
            eyebrow: "DIN PERSONLIGA MIX",
            trailing: "Blandat",
            items: watchlistMix
        )
    }

    private var hiddenGemsSection: some View {
        posterCarousel(
            title: "Dolda pärlor",
            eyebrow: "HÖGA BETYG · VÄRDA ATT UPPTÄCKA",
            trailing: "Upptäck",
            items: hiddenGems
        )
    }

    @ViewBuilder
    private func posterCarousel(title: String, eyebrow: String, trailing: String, items: [MediaItem]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeading(title, eyebrow: eyebrow, trailing: trailing)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 13) {
                        ForEach(items, id: \.stableID) { item in
                            NavigationLink(value: item) {
                                MediaPosterTile(item: item, rank: (items.firstIndex(of: item) ?? 0) + 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
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
                                ForEach(personalRecommendations, id: \.stableID) { item in
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
        let requestID = UUID()
        recommendationRequestID = requestID

        guard TMDBConfiguration.isConfigured else {
            personalRecommendations = []
            isLoadingRecommendations = false
            return
        }

        let seeds = libraryEntries
            .filter { $0.isFavorite || ($0.personalRating ?? 0) >= 8 }
            .sorted {
                let firstScore = ($0.isFavorite ? 100 : 0) + ($0.personalRating ?? 0)
                let secondScore = ($1.isFavorite ? 100 : 0) + ($1.personalRating ?? 0)
                if firstScore != secondScore { return firstScore > secondScore }
                return $0.dateUpdated > $1.dateUpdated
            }
            .prefix(3)

        guard !seeds.isEmpty else {
            personalRecommendations = []
            isLoadingRecommendations = false
            return
        }

        isLoadingRecommendations = true
        defer {
            if recommendationRequestID == requestID {
                isLoadingRecommendations = false
            }
        }

        let client = TMDBConfiguration.makeClient()
        let savedIDs = Set(libraryEntries.map(\.stableID))
        var seedResults: [[MediaItem]] = []

        for seed in seeds {
            guard !Task.isCancelled, recommendationRequestID == requestID else { return }
            do {
                let similar = try await client.similarTitles(to: seed.mediaItem)
                guard !Task.isCancelled, recommendationRequestID == requestID else { return }
                seedResults.append(similar.filter {
                    !savedIDs.contains($0.stableID) && $0.id > 0
                })
            } catch {
                guard !Task.isCancelled, recommendationRequestID == requestID else { return }
                seedResults.append([])
            }
        }

        // Interleave the strongest matches from each seed so one favorite cannot dominate the feed.
        var recommendations: [MediaItem] = []
        var recommendedIDs = Set<String>()
        let longestResult = seedResults.map(\.count).max() ?? 0
        for index in 0..<longestResult {
            for results in seedResults where index < results.count {
                let item = results[index]
                guard recommendedIDs.insert(item.stableID).inserted else { continue }
                recommendations.append(item)
                if recommendations.count == 12 { break }
            }
            if recommendations.count == 12 { break }
        }

        guard !Task.isCancelled, recommendationRequestID == requestID else { return }
        personalRecommendations = recommendations
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
                let discoveryItems = visibleTrendingItems.filter { $0.stableID != trendingItems.first?.stableID }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 13) {
                        ForEach(discoveryItems.prefix(12), id: \.stableID) { item in
                            NavigationLink(value: item) {
                                MediaPosterTile(item: item, rank: (discoveryItems.firstIndex(of: item) ?? 0) + 2)
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

        let client = TMDBConfiguration.makeClient()
        async let trending = client.trendingThisWeek()
        async let gems = client.hiddenGems()

        do {
            trendingItems = try await trending
        } catch {
            trendingError = error.localizedDescription
        }

        do {
            hiddenGemItems = try await gems
        } catch {
            hiddenGemItems = []
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

private struct HomeUpNextItem: Identifiable {
    let entry: LibraryEntry
    let series: MediaItem
    let episode: TVNextEpisode
    let airDate: Date

    var id: String { "\(entry.stableID)-\(episode.id)" }
}
