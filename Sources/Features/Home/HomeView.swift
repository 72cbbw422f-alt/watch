import SwiftUI
import SwiftData

struct HomeView: View {
    let onExplore: () -> Void
    let onCalendar: () -> Void

    @State private var selectedFilter = "Alla"
    @State private var trendingItems: [MediaItem] = []
    @State private var hiddenGemItems: [MediaItem] = []
    @State private var isLoadingTrending = false
    @State private var trendingError: String?
    @State private var trendingRequestID = UUID()
    @State private var personalRecommendations: [MediaItem] = []
    @State private var isLoadingRecommendations = false
    @State private var recommendationRequestID = UUID()
    @State private var continueWatchingNextEpisodes: [String: TVEpisode] = [:]
    @State private var continueWatchingRequestID = UUID()
    @Query(sort: \LibraryEntry.dateUpdated, order: .reverse) private var libraryEntries: [LibraryEntry]
    @Query private var episodeProgressEntries: [EpisodeProgress]

    private var inProgressEntries: [LibraryEntry] { libraryEntries.filter { $0.status == .watching } }

    private var savedForLaterEntries: [LibraryEntry] {
        libraryEntries
            .filter { $0.status == .wantToWatch || $0.status == .monitoring }
            .sorted { $0.dateAdded > $1.dateAdded }
    }

    private var continueWatchingSeedKey: String {
        let activeSeries = inProgressEntries
            .filter { $0.mediaKind == MediaKind.television.rawValue }
            .map(\.stableID)
            .sorted()
            .joined(separator: "|")
        let progress = episodeProgressEntries
            .sorted { $0.stableID < $1.stableID }
            .map { "\($0.stableID):\($0.isWatched)" }
            .joined(separator: "|")
        return activeSeries + "#progress:" + progress
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

    private let filters = ["Alla", "Filmer", "Serier"]

    private var savedStableIDs: Set<String> { Set(libraryEntries.map(\.stableID)) }

    private var tonightItems: [MediaItem] {
        // A short, immediate shortlist; the remaining titles can populate the mixed shelf.
        var seen = Set(personalRecommendations.map(\.stableID))
        if let featuredID = trendingItems.first?.stableID {
            seen.insert(featuredID)
        }
        return trendingItems.filter {
            seen.insert($0.stableID).inserted && !savedStableIDs.contains($0.stableID)
        }.prefix(8).map { $0 }
    }

    private var hiddenGems: [MediaItem] {
        let trendingIDs = Set(trendingItems.map(\.stableID))
        return hiddenGemItems
            .filter { !savedStableIDs.contains($0.stableID) && !trendingIDs.contains($0.stableID) }
            .prefix(10)
            .map { $0 }
    }

    private var watchlistMix: [MediaItem] {
        // Fill this shelf with titles not already shown in the hero or adjacent shelves.
        var seen = Set(tonightItems.map(\.stableID))
        seen.formUnion(personalRecommendations.map(\.stableID))
        seen.formUnion(hiddenGems.map(\.stableID))
        if let featuredID = trendingItems.first?.stableID {
            seen.insert(featuredID)
        }
        return trendingItems.filter {
            seen.insert($0.stableID).inserted && !savedStableIDs.contains($0.stableID)
        }.prefix(12).map { $0 }
    }

    var body: some View {
        ZStack {
            WatchlistColor.background.ignoresSafeArea()

            GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {
                        header
                        featured
                        homeUpNext
                        recommendations
                        tonightPicks
                        continueWatching
                        watchlistMixSection
                        hiddenGemsSection
                        quickFilters
                        trending
                        premieres
                        comingSoon
                    }
                    .frame(width: geometry.size.width, alignment: .leading)
                    .padding(.top, 10)
                    .padding(.bottom, 34)
                }
                .frame(width: geometry.size.width, alignment: .leading)
                .refreshable {
                    await loadTrending()
                    await loadPersonalRecommendations()
                        }
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
        .task(id: continueWatchingSeedKey) {
            await loadContinueWatchingEpisodes()
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

    private var featuredItems: [MediaItem] {
        guard let first = trendingItems.first else { return [] }
        var result = [first]
        var remaining = Array(trendingItems.dropFirst())
        while result.count < 5, !remaining.isEmpty {
            let preferredKind: MediaKind = result.last?.kind == .movie ? .television : .movie
            let nextIndex = remaining.firstIndex { $0.kind == preferredKind } ?? 0
            result.append(remaining.remove(at: nextIndex))
        }
        return result
    }

    private var featured: some View {
        Group {
            if !featuredItems.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(featuredItems, id: \.stableID) { item in
                            featuredCard(for: item)
                                .containerRelativeFrame(.horizontal) { width, _ in width - 40 }
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, 20, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned)
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
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
        }
    }

    private func featuredCard(for item: MediaItem) -> some View {
        NavigationLink(value: item) {
            ZStack(alignment: .bottomLeading) {
                Rectangle()
                    .fill(WatchlistColor.surfaceElevated)
                GeometryReader { proxy in
                    Group {
                        if let url = item.backdropURL {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image.resizable()
                                        .scaledToFill()
                                        .frame(width: proxy.size.width, height: proxy.size.height)
                                        .clipped()
                                } else {
                                    heroFallback
                                }
                            }
                        } else {
                            heroFallback
                        }
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
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
                    Text("UTVALT FÖR DIG")
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
        let entries = inProgressEntries.filter {
            $0.mediaKind == MediaKind.television.rawValue &&
            continueWatchingNextEpisodes[$0.stableID] != nil
        }

        return Group {
            if !entries.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    sectionHeading(
                        "Up Next",
                        eyebrow: "NÄSTA AVSNITT I DINA SERIER",
                        trailing: "\(entries.count) SERIER"
                    )
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(entries.prefix(10)) { entry in
                                NavigationLink(value: entry.mediaItem) {
                                    UpNextEpisodeCard(
                                        entry: entry,
                                        episode: continueWatchingNextEpisodes[entry.stableID]
                                    )
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

    @MainActor
    private func loadContinueWatchingEpisodes() async {
        let series = inProgressEntries.filter { $0.mediaKind == MediaKind.television.rawValue }
        let requestID = UUID()
        continueWatchingRequestID = requestID
        guard TMDBConfiguration.isConfigured, !series.isEmpty else {
            continueWatchingNextEpisodes = [:]
            return
        }

        let client = TMDBConfiguration.makeClient()
        let seeds = series.map { (stableID: $0.stableID, tmdbID: $0.tmdbID) }
        let watchedKeys = Set(episodeProgressEntries.filter(\.isWatched).map {
            "\($0.seriesID):\($0.seasonNumber):\($0.episodeNumber)"
        })
        var results: [String: TVEpisode] = [:]

        await withTaskGroup(of: (String, TVEpisode?).self) { group in
            for seed in seeds {
                group.addTask {
                    do {
                        let details = try await client.televisionDetails(id: seed.tmdbID)
                        var episodes: [TVEpisode] = []
                        for season in details.regularSeasons {
                            let seasonDetails = try await client.televisionSeason(
                                id: seed.tmdbID,
                                seasonNumber: season.seasonNumber
                            )
                            episodes.append(contentsOf: seasonDetails.episodes)
                        }
                        let next = TVEpisodeSelection.nextUnwatchedEpisode(
                            in: episodes,
                            seriesID: seed.tmdbID,
                            watchedKeys: watchedKeys
                        )
                        return (seed.stableID, next)
                    } catch {
                        return (seed.stableID, nil)
                    }
                }
            }

            for await (stableID, episode) in group {
                guard !Task.isCancelled, continueWatchingRequestID == requestID else {
                    group.cancelAll()
                    return
                }
                if let episode { results[stableID] = episode }
            }
        }

        guard !Task.isCancelled, continueWatchingRequestID == requestID else { return }
        continueWatchingNextEpisodes = results
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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(inProgressEntries.prefix(8)) { entry in
                            NavigationLink(value: entry.mediaItem) {
                                ContinueWatchingCard(
                                    entry: entry,
                                    nextEpisode: continueWatchingNextEpisodes[entry.stableID]
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
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
        // Snapshot SwiftData-backed values before crossing task boundaries.
        let seedItems = seeds.map { $0.mediaItem }
        var seedResults = Array(repeating: [MediaItem](), count: seedItems.count)

        await withTaskGroup(of: (Int, [MediaItem]).self) { group in
            for (index, seedItem) in seedItems.enumerated() {
                group.addTask {
                    let results = (try? await client.similarTitles(to: seedItem)) ?? []
                    let filtered = results.filter {
                        !savedIDs.contains($0.stableID) && $0.id > 0
                    }
                    return (index, filtered)
                }
            }

            for await (index, results) in group {
                guard !Task.isCancelled, recommendationRequestID == requestID else {
                    group.cancelAll()
                    return
                }
                seedResults[index] = results
            }
        }

        guard !Task.isCancelled, recommendationRequestID == requestID else { return }

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

        let requestID = UUID()
        trendingRequestID = requestID
        isLoadingTrending = true
        trendingError = nil
        defer {
            if trendingRequestID == requestID {
                isLoadingTrending = false
            }
        }

        let client = TMDBConfiguration.makeClient()
        async let trending = client.trendingThisWeek()
        async let gems = client.hiddenGems()

        do {
            let results = try await trending
            guard !Task.isCancelled, trendingRequestID == requestID else { return }
            trendingItems = results
        } catch {
            guard !Task.isCancelled, trendingRequestID == requestID else { return }
            trendingError = error.localizedDescription
        }

        do {
            let results = try await gems
            guard !Task.isCancelled, trendingRequestID == requestID else { return }
            hiddenGemItems = results
        } catch {
            guard !Task.isCancelled, trendingRequestID == requestID else { return }
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
            sectionHeading("Din lista", eyebrow: "SPARAT FÖR SENARE", trailing: "\(savedForLaterEntries.count) SPARADE")
            if savedForLaterEntries.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(WatchlistColor.accent)
                        .frame(width: 38, height: 38)
                        .background(WatchlistColor.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Din lista väntar på innehåll")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(WatchlistColor.primaryText)
                        Text("Spara filmer och serier som du vill se senare så samlas de här.")
                            .font(.system(size: 11))
                            .foregroundStyle(WatchlistColor.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(WatchlistColor.hairline, lineWidth: 1))
                .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 13) {
                        ForEach(Array(savedForLaterEntries.prefix(12).enumerated()), id: \.element.stableID) { index, entry in
                            NavigationLink(value: entry.mediaItem) {
                                MediaPosterTile(item: entry.mediaItem, rank: index + 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
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
                .font(.system(size: 9, weight: .bold))
                .tracking(0.65)
                .foregroundStyle(WatchlistColor.secondaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(WatchlistColor.surface, in: Capsule())
                .overlay(Capsule().stroke(WatchlistColor.hairline, lineWidth: 1))
        }
        .padding(.horizontal, 20)
    }
}


private struct UpNextEpisodeCard: View {
    let entry: LibraryEntry
    let episode: TVEpisode?

    var body: some View {
        HStack(spacing: 12) {
            LibraryHomePoster(entry: entry, width: 58, height: 82)
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(WatchlistColor.primaryText)
                    .lineLimit(1)
                if let episode {
                    Text(episode.displayCode.uppercased())
                        .font(.system(size: 8, weight: .bold))
                        .tracking(0.9)
                        .foregroundStyle(WatchlistColor.accent)
                    Text(episode.name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(WatchlistColor.secondaryText)
                        .lineLimit(2)
                } else {
                    Text("Nästa avsnitt")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(WatchlistColor.secondaryText)
                }
                Label("Visa serie", systemImage: "play.fill")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(WatchlistColor.accent)
            }
            Spacer(minLength: 0)
        }
        .padding(11)
        .frame(width: 245, height: 106, alignment: .leading)
        .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(WatchlistColor.hairline, lineWidth: 1))
    }
}


private struct ContinueWatchingCard: View {
    let entry: LibraryEntry
    let nextEpisode: TVEpisode?

    var body: some View {
        HStack(spacing: 13) {
            LibraryHomePoster(entry: entry, width: 70, height: 98)
            VStack(alignment: .leading, spacing: 7) {
                Text(entry.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(WatchlistColor.primaryText)
                    .lineLimit(2)
                Text(entry.mediaKind == "movie" ? "FILM" : "SERIE")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.1)
                    .foregroundStyle(WatchlistColor.mutedText)
                Label("Tittar på", systemImage: "play.circle.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(WatchlistColor.accent)
                if entry.mediaKind == MediaKind.television.rawValue {
                    nextEpisodeInformation
                }
            }
            Spacer(minLength: 0)
        }
        .padding(13)
        .frame(width: 310, height: 136, alignment: .leading)
        .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 17).stroke(WatchlistColor.hairline, lineWidth: 1))
    }

    @ViewBuilder
    private var nextEpisodeInformation: some View {
        if let nextEpisode {
            episodeLabel("\(nextEpisode.displayCode) · \(nextEpisode.name)")
        } else if let code = entry.nextEpisodeCode, !code.isEmpty {
            episodeLabel([code, entry.nextEpisodeTitle ?? ""].filter { !$0.isEmpty }.joined(separator: " · "))
        }
    }

    private func episodeLabel(_ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("NÄSTA AVSNITT")
                .font(.system(size: 8, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(WatchlistColor.mutedText)
            Text(value)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(WatchlistColor.primaryText)
                .lineLimit(2)
        }
        .padding(.top, 1)
    }
}

private struct LibraryHomePoster: View {
    let entry: LibraryEntry
    var width: CGFloat = 48
    var height: CGFloat = 66

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
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 9))
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

    @Environment(\.modelContext) private var modelContext
    @Query private var libraryEntries: [LibraryEntry]

    private var savedEntry: LibraryEntry? {
        libraryEntries.first { $0.stableID == item.stableID }
    }

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
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                toggleFavorite()
            } label: {
                Label(savedEntry?.isFavorite == true ? "Ta bort favorit" : "Lägg till i favoriter",
                      systemImage: savedEntry?.isFavorite == true ? "heart.slash" : "heart")
            }

            Menu("Ändra status") {
                ForEach(LibraryStatus.allCases) { status in
                    Button {
                        setStatus(status)
                    } label: {
                        Label(status.title, systemImage: status.symbol)
                    }
                }
            }

            if savedEntry != nil {
                Button(role: .destructive) {
                    removeFromLibrary()
                } label: {
                    Label("Ta bort från min lista", systemImage: "trash")
                }
            }
        }
    }

    private func toggleFavorite() {
        let entry = savedEntry ?? LibraryEntry(item: item)
        if savedEntry == nil { modelContext.insert(entry) }
        entry.isFavorite.toggle()
        entry.dateUpdated = .now
        try? modelContext.save()
    }

    private func setStatus(_ status: LibraryStatus) {
        let entry = savedEntry ?? LibraryEntry(item: item, status: status)
        if savedEntry == nil { modelContext.insert(entry) }
        entry.status = status
        try? modelContext.save()
    }

    private func removeFromLibrary() {
        guard let entry = savedEntry else { return }
        modelContext.delete(entry)
        try? modelContext.save()
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
