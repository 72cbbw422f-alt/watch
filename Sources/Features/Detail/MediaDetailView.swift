import SwiftUI
import SwiftData

struct MediaDetailView: View {
    let item: MediaItem

    @Environment(\.modelContext) private var modelContext
    @Query private var libraryEntries: [LibraryEntry]
    @Query private var episodeProgressEntries: [EpisodeProgress]
    @Query private var movieWatchEvents: [MovieWatchEvent]
    @Query(sort: \CustomList.name) private var customLists: [CustomList]
    @Query private var customListItems: [CustomListItem]
    @State private var persistenceError: String?
    @State private var televisionSeasons: [TVSeason] = []
    @State private var nextEpisodeToAir: TVNextEpisode?
    @State private var lastEpisodeToAir: TVNextEpisode?
    @State private var episodesBySeason: [Int: [TVEpisode]] = [:]
    @State private var expandedSeason: Int?
    @State private var isLoadingSeasons = false
    @State private var loadingSeasonNumber: Int?
    @State private var seasonError: String?
    @State private var seasonEpisodeErrors: [Int: String] = [:]
    @State private var similarItems: [MediaItem] = []
    @State private var isLoadingSimilar = false
    @State private var tmdbVideos: [TMDBVideo] = []
    @State private var isLoadingVideos = false
    @State private var videosError: String?
    @State private var hasLoadedVideos = false
    @State private var tmdbReviews: [TMDBReview] = []
    @State private var isLoadingReviews = false
    @State private var reviewsError: String?
    @State private var hasLoadedReviews = false
    @State private var reviewPage = 1
    @State private var totalReviewPages = 1
    @State private var expandedReviewIDs: Set<String> = []
    @State private var watchProviderResult: TMDBWatchProviderResult?
    @State private var isLoadingWatchProviders = false
    @State private var watchProvidersError: String?
    @State private var hasLoadedWatchProviders = false
    var body: some View {
        ZStack {
            WatchlistColor.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    artworkHeader
                    metadata
                    watchProvidersSection
                    libraryActions
                    movieHistorySection
                    PersonalReviewSection(
                        rating: libraryEntry?.personalRating,
                        notes: libraryEntry?.personalNotes ?? "",
                        onRatingChange: updatePersonalRating,
                        onNotesSave: updatePersonalNotes
                    )
                    .padding(.horizontal, 20)
                    addToCustomListSection
                    if !item.overview.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: 9) {
                            sectionLabel("OM TITELN")
                            Text(item.overview)
                                .font(.system(size: 14))
                                .foregroundStyle(WatchlistColor.secondaryText)
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    trailersSection
                    tmdbReviewsSection
                    upNextSection
                    televisionSeasonsSection
                    similarTitlesSection
                    sourceNote
                }
                .padding(.bottom, 36)
            }
            .ignoresSafeArea(edges: .top)
        }
        .toolbar(.visible, for: .navigationBar)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .task {
            await loadTelevisionSeasons()
            await loadSimilarTitles()
            await loadReviews()
            await loadVideos()
            await loadWatchProviders()
        }
        .alert("Kunde inte spara ändringen", isPresented: Binding(
            get: { persistenceError != nil },
            set: { if !$0 { persistenceError = nil } }
        )) {
            Button("OK", role: .cancel) { persistenceError = nil }
        } message: {
            Text(persistenceError ?? "Ett oväntat fel uppstod.")
        }
    }

    private var artworkHeader: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let url = item.backdropURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .empty, .failure:
                            backdropPlaceholder
                        @unknown default:
                            backdropPlaceholder
                        }
                    }
                } else {
                    backdropPlaceholder
                }
            }
            .frame(height: 390)
            .frame(maxWidth: .infinity)
            .clipped()

            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.05), location: 0),
                    .init(color: .black.opacity(0.18), location: 0.42),
                    .init(color: WatchlistColor.background, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            HStack(alignment: .bottom, spacing: 16) {
                poster
                VStack(alignment: .leading, spacing: 7) {
                    Text(item.kind.displayName.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.8)
                        .foregroundStyle(WatchlistColor.accent)
                    Text(item.title)
                        .font(.system(size: 27, weight: .bold, design: .rounded))
                        .tracking(-0.7)
                        .foregroundStyle(WatchlistColor.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 5)
        }
        .frame(height: 390)
    }

    @ViewBuilder
    private var poster: some View {
        if let url = item.posterURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .empty, .failure:
                    posterPlaceholder
                @unknown default:
                    posterPlaceholder
                }
            }
            .frame(width: 104, height: 154)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(.white.opacity(0.14), lineWidth: 1))
            .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
        } else {
            posterPlaceholder
        }
    }

    private var posterPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(WatchlistColor.surfaceElevated)
            .overlay {
                Image(systemName: item.kind == .movie ? "film" : "tv")
                    .font(.system(size: 25, weight: .light))
                    .foregroundStyle(WatchlistColor.mutedText)
            }
            .frame(width: 104, height: 154)
    }

    private var backdropPlaceholder: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color(hex: 0x493020), WatchlistColor.background, Color(hex: 0x171311)],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
            )
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(WatchlistColor.accent.opacity(0.16))
                    .frame(width: 180, height: 180)
                    .blur(radius: 55)
                    .offset(x: 45, y: -30)
            }
    }





    @ViewBuilder
    private var watchProvidersSection: some View {
        if isLoadingWatchProviders && watchProviderResult == nil {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("VAR DU KAN STREAMA")
                ProgressView().tint(WatchlistColor.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .padding(.horizontal, 20)
        } else if hasLoadedWatchProviders || watchProvidersError != nil {
            VStack(alignment: .leading, spacing: 13) {
                HStack {
                    sectionLabel("VAR DU KAN STREAMA")
                    Spacer()
                    Text("SVERIGE")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(WatchlistColor.mutedText)
                }

                if let result = watchProviderResult, result.hasAnyProvider {
                    providerGroup(title: "STREAMING", providers: result.flatrate ?? [], link: result.link)
                    providerGroup(title: "GRATIS", providers: result.free ?? [], link: result.link)
                    providerGroup(title: "MED REKLAM", providers: result.ads ?? [], link: result.link)
                    providerGroup(title: "HYR", providers: result.rent ?? [], link: result.link)
                    providerGroup(title: "KÖP", providers: result.buy ?? [], link: result.link)
                    if let link = result.link {
                        Link(destination: link) {
                            HStack(spacing: 6) {
                                Text("Visa alla alternativ")
                                Image(systemName: "arrow.up.right")
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(WatchlistColor.accent)
                        }
                    }
                } else if watchProvidersError == nil {
                    Text("Vi hittar inga aktuella streamingalternativ i Sverige för den här titeln.")
                        .font(.system(size: 12))
                        .foregroundStyle(WatchlistColor.secondaryText)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 14))
                }

                if let watchProvidersError {
                    Text(watchProvidersError)
                        .font(.system(size: 11))
                        .foregroundStyle(WatchlistColor.secondaryText)
                    Button("Försök igen") {
                        Task { await loadWatchProviders() }
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WatchlistColor.accent)
                }
                Text("Tillgänglighet kan ändras. Uppgifterna kommer från TMDB.")
                    .font(.system(size: 9))
                    .foregroundStyle(WatchlistColor.mutedText)
            }
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private func providerGroup(title: String, providers: [TMDBWatchProvider], link: URL?) -> some View {
        if !providers.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(WatchlistColor.secondaryText)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(providers) { provider in
                            VStack(spacing: 5) {
                                Group {
                                    if let logoURL = provider.logoURL {
                                        AsyncImage(url: logoURL) { phase in
                                            if let image = phase.image {
                                                image.resizable().scaledToFit()
                                            } else {
                                                providerLogoPlaceholder
                                            }
                                        }
                                    } else {
                                        providerLogoPlaceholder
                                    }
                                }
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 11))
                                Text(provider.providerName)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(WatchlistColor.secondaryText)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 66)
                            }
                        }
                    }
                }
            }
        }
    }

    private var providerLogoPlaceholder: some View {
        RoundedRectangle(cornerRadius: 11)
            .fill(WatchlistColor.surfaceElevated)
            .overlay {
                Image(systemName: "play.rectangle")
                    .font(.system(size: 17))
                    .foregroundStyle(WatchlistColor.mutedText)
            }
    }

    @MainActor
    private func loadWatchProviders() async {
        guard !isLoadingWatchProviders else { return }
        guard TMDBConfiguration.isConfigured else {
            watchProvidersError = "Lägg till din TMDB-token för att visa streamingtjänster."
            return
        }
        isLoadingWatchProviders = true
        watchProvidersError = nil
        defer { isLoadingWatchProviders = false }
        do {
            watchProviderResult = try await TMDBConfiguration.makeClient().watchProviders(for: item)
            hasLoadedWatchProviders = true
        } catch {
            watchProvidersError = "Streaminginformationen kunde inte hämtas just nu."
        }
    }

    @ViewBuilder
    private var trailersSection: some View {
        if isLoadingVideos && tmdbVideos.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("TRAILERS & VIDEOKLIPP")
                ProgressView().tint(WatchlistColor.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            }
            .padding(.horizontal, 20)
        } else if hasLoadedVideos || videosError != nil {
            VStack(alignment: .leading, spacing: 13) {
                sectionLabel("TRAILERS & VIDEOKLIPP")
                if tmdbVideos.isEmpty && videosError == nil {
                    Text("Ingen trailer finns tillgänglig för den här titeln ännu.")
                        .font(.system(size: 12))
                        .foregroundStyle(WatchlistColor.secondaryText)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 14))
                }
                ForEach(tmdbVideos) { video in
                    if let url = video.playbackURL {
                        Link(destination: url) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(WatchlistColor.surfaceElevated)
                                        .frame(width: 76, height: 54)
                                    Image(systemName: video.type == "Trailer" ? "play.fill" : "video")
                                        .font(.system(size: 19, weight: .semibold))
                                        .foregroundStyle(WatchlistColor.accent)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(video.name)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(WatchlistColor.primaryText)
                                        .lineLimit(2)
                                    Text("\(video.type) · \(video.site)\(video.official ? " · Officiell" : "")")
                                        .font(.system(size: 10))
                                        .foregroundStyle(WatchlistColor.secondaryText)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(WatchlistColor.mutedText)
                            }
                            .padding(11)
                            .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 13))
                        }
                        .buttonStyle(.plain)
                    }
                }
                if let videosError {
                    Text(videosError)
                        .font(.system(size: 11))
                        .foregroundStyle(WatchlistColor.secondaryText)
                    Button("Försök igen") {
                        Task { await loadVideos() }
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WatchlistColor.accent)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    @MainActor
    private func loadVideos() async {
        guard !isLoadingVideos else { return }
        guard TMDBConfiguration.isConfigured else {
            videosError = "Lägg till din TMDB-token för att visa trailers."
            return
        }
        isLoadingVideos = true
        videosError = nil
        defer { isLoadingVideos = false }
        do {
            tmdbVideos = try await TMDBConfiguration.makeClient().videos(for: item)
            hasLoadedVideos = true
        } catch {
            videosError = "Videoklippen kunde inte hämtas just nu."
        }
    }

    @ViewBuilder
    private var tmdbReviewsSection: some View {
        if isLoadingReviews && tmdbReviews.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("RECENSIONER FRÅN TMDB")
                ProgressView()
                    .tint(WatchlistColor.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            }
            .padding(.horizontal, 20)
        } else if hasLoadedReviews || reviewsError != nil {
            VStack(alignment: .leading, spacing: 13) {
                HStack {
                    sectionLabel("RECENSIONER FRÅN TMDB")
                    Spacer()
                    Text("\(tmdbReviews.count) hämtade")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(WatchlistColor.mutedText)
                }

                if tmdbReviews.isEmpty && reviewsError == nil {
                    Text("Det finns inga publicerade recensioner för den här titeln ännu.")
                        .font(.system(size: 12))
                        .foregroundStyle(WatchlistColor.secondaryText)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 14))
                }

                ForEach(tmdbReviews) { review in
                    reviewCard(review)
                }

                if let reviewsError {
                    Text(reviewsError)
                        .font(.system(size: 11))
                        .foregroundStyle(WatchlistColor.secondaryText)
                    Button("Försök igen") {
                        Task { await loadReviews() }
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WatchlistColor.accent)
                } else if reviewPage < totalReviewPages {
                    Button {
                        Task { await loadMoreReviews() }
                    } label: {
                        HStack(spacing: 8) {
                            if isLoadingReviews {
                                ProgressView().tint(WatchlistColor.accent)
                            }
                            Text("Visa fler recensioner")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(WatchlistColor.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoadingReviews)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func reviewCard(_ review: TMDBReview) -> some View {
        let isExpanded = expandedReviewIDs.contains(review.id)
        return VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(review.author.isEmpty ? "TMDB-användare" : review.author)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(WatchlistColor.primaryText)
                    Text(String(review.createdAt.prefix(10)))
                        .font(.system(size: 10))
                        .foregroundStyle(WatchlistColor.mutedText)
                }
                Spacer()
                if let rating = review.authorDetails.rating {
                    Label(String(format: "%.1f", rating), systemImage: "star.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(WatchlistColor.accent)
                }
            }

            Text(review.content)
                .font(.system(size: 12))
                .foregroundStyle(WatchlistColor.secondaryText)
                .lineSpacing(4)
                .lineLimit(isExpanded ? nil : 6)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button(isExpanded ? "Visa mindre" : "Läs hela recensionen") {
                    if isExpanded {
                        expandedReviewIDs.remove(review.id)
                    } else {
                        expandedReviewIDs.insert(review.id)
                    }
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(WatchlistColor.accent)
                Spacer()
                if let url = review.url {
                    Link("Original hos TMDB", destination: url)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(WatchlistColor.mutedText)
                }
            }
        }
        .padding(14)
        .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 14))
    }

    @MainActor
    private func loadReviews() async {
        guard !isLoadingReviews else { return }
        guard TMDBConfiguration.isConfigured else {
            reviewsError = "Lägg till din TMDB-token för att läsa recensioner."
            return
        }
        isLoadingReviews = true
        reviewsError = nil
        defer { isLoadingReviews = false }
        do {
            let page = try await TMDBConfiguration.makeClient().reviews(for: item)
            tmdbReviews = page.results
            hasLoadedReviews = true
            reviewPage = page.page
            totalReviewPages = page.totalPages
        } catch {
            reviewsError = "Recensionerna kunde inte hämtas just nu."
        }
    }

    @MainActor
    private func loadMoreReviews() async {
        guard !isLoadingReviews, reviewPage < totalReviewPages else { return }
        isLoadingReviews = true
        defer { isLoadingReviews = false }
        do {
            let page = try await TMDBConfiguration.makeClient().reviews(for: item, page: reviewPage + 1)
            tmdbReviews.append(contentsOf: page.results)
            reviewPage = page.page
            totalReviewPages = page.totalPages
        } catch {
            reviewsError = "Fler recensioner kunde inte hämtas. Försök igen."
        }
    }

    @ViewBuilder
    private var similarTitlesSection: some View {
        if isLoadingSimilar || !similarItems.isEmpty {
            VStack(alignment: .leading, spacing: 13) {
                sectionLabel("DU KANSKE OCKSÅ GILLAR")
                if isLoadingSimilar && similarItems.isEmpty {
                    ProgressView()
                        .tint(WatchlistColor.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(similarItems.prefix(10)) { recommendation in
                                NavigationLink(value: recommendation) {
                                    SimilarTitleTile(item: recommendation)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, -20)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    @MainActor
    private func loadSimilarTitles() async {
        isLoadingSimilar = true
        defer { isLoadingSimilar = false }
        do {
            let results = try await TMDBConfiguration.makeClient().similarTitles(to: item)
            let savedIDs = Set(libraryEntries.map(\.stableID))
            similarItems = results.filter {
                $0.id > 0 && !savedIDs.contains($0.stableID)
            }
        } catch {
            similarItems = []
        }
    }

    private var libraryEntry: LibraryEntry? {
        libraryEntries.first { $0.stableID == item.stableID }
    }

    private var libraryActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let entry = libraryEntry {
                HStack(spacing: 10) {
                    Label(entry.status.title, systemImage: entry.status.symbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(WatchlistColor.accent)
                    Spacer()
                    Menu {
                        ForEach(LibraryStatus.allCases) { status in
                            Button {
                                let previousStatus = entry.statusRawValue
                                let previousUpdatedAt = entry.dateUpdated
                                entry.status = status
                                do {
                                    try modelContext.save()
                                    persistenceError = nil
                                } catch {
                                    let saveError = error.localizedDescription
                                    entry.statusRawValue = previousStatus
                                    entry.dateUpdated = previousUpdatedAt
                                    do {
                                        try modelContext.save()
                                        persistenceError = saveError
                                    } catch {
                                        persistenceError = "Biblioteksstatusen kunde inte återställas: \\(error.localizedDescription)"
                                    }
                                }
                            } label: {
                                Label(status.title, systemImage: status.symbol)
                            }
                        }
                        Button(role: .destructive) {
                            modelContext.delete(entry)
                            do {
                                try modelContext.save()
                                persistenceError = nil
                            } catch {
                                let saveError = error.localizedDescription
                                modelContext.insert(entry)
                                do {
                                    try modelContext.save()
                                    persistenceError = saveError
                                } catch {
                                    persistenceError = "Biblioteksposten kunde inte återställas: \\(error.localizedDescription)"
                                }
                            }
                        } label: {
                            Label("Ta bort från bibliotek", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 21))
                            .foregroundStyle(WatchlistColor.secondaryText)
                    }
                }
                .padding(15)
                .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 16))
                favoriteButton(isFavorite: entry.isFavorite)
            } else {
                Menu {
                    ForEach(LibraryStatus.allCases) { status in
                        Button {
                            addToLibrary(status: status)
                        } label: {
                            Label(status.title, systemImage: status.symbol)
                        }
                    }
                } label: {
                    Label("Lägg till i min lista", systemImage: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(WatchlistColor.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(WatchlistColor.accent, in: RoundedRectangle(cornerRadius: 15))
                }
                favoriteButton(isFavorite: false)
            }
        }
        .padding(.horizontal, 20)
    }

    private func addToLibrary(status: LibraryStatus) {
        let entry = LibraryEntry(item: item, status: status)
        if item.kind == .television && !televisionSeasons.isEmpty {
            entry.episodeTotalCount = televisionSeasons.reduce(0) { $0 + $1.episodeCount }
            entry.nextEpisodeTitle = nextEpisodeToAir?.name
            entry.nextEpisodeCode = nextEpisodeToAir?.displayCode
            entry.nextEpisodeAirDate = nextEpisodeToAir?.airDate
        }
        modelContext.insert(entry)
        do {
            try modelContext.save()
            persistenceError = nil
        } catch {
            let saveError = error.localizedDescription
            modelContext.delete(entry)
            do {
                try modelContext.save()
                persistenceError = saveError
            } catch {
                persistenceError = "Biblioteksposten kunde inte återställas: \\(error.localizedDescription)"
            }
        }
    }

    @ViewBuilder
    private var movieHistorySection: some View {
        if item.kind == .movie {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("TITTARHISTORIK")
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(movieWatchEvents.filter { $0.tmdbID == item.id }.count == 0
                             ? "Har du sett filmen?"
                             : "Sedd \(movieWatchEvents.filter { $0.tmdbID == item.id }.count) gånger")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(WatchlistColor.primaryText)
                        Text("Varje registrering sparas separat, även omtittningar.")
                            .font(.system(size: 10))
                            .foregroundStyle(WatchlistColor.secondaryText)
                    }
                    Spacer()
                    Button {
                        registerMovieViewing()
                    } label: {
                        Label("Registrera", systemImage: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(WatchlistColor.background)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 10)
                            .background(WatchlistColor.accent, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
                .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
        }
    }

    private func registerMovieViewing() {
        let existingEntry = libraryEntry
        let previousStatus = existingEntry?.statusRawValue
        let previousUpdatedAt = existingEntry?.dateUpdated
        let entry = existingEntry ?? LibraryEntry(item: item, status: .watched)
        let event = MovieWatchEvent(
            tmdbID: item.id,
            title: item.title,
            posterPath: item.posterPath
        )

        modelContext.insert(event)
        if existingEntry == nil {
            modelContext.insert(entry)
        }
        entry.status = .watched

        do {
            try modelContext.save()
            persistenceError = nil
        } catch {
            let saveError = error.localizedDescription
            modelContext.delete(event)

            if let previousStatus, let previousUpdatedAt {
                entry.statusRawValue = previousStatus
                entry.dateUpdated = previousUpdatedAt
            } else {
                modelContext.delete(entry)
            }

            do {
                try modelContext.save()
                persistenceError = saveError
            } catch {
                persistenceError = "Visningen kunde inte sparas och ändringen kunde inte återställas: \(error.localizedDescription)"
            }
        }
    }

    private func favoriteButton(isFavorite: Bool) -> some View {
        Button {
            let existingEntry = libraryEntry
            let previousFavorite = existingEntry?.isFavorite
            let previousUpdatedAt = existingEntry?.dateUpdated
            let entry = existingEntry ?? LibraryEntry(item: item)
            if existingEntry == nil {
                if item.kind == .television && !televisionSeasons.isEmpty {
                    entry.episodeTotalCount = televisionSeasons.reduce(0) { $0 + $1.episodeCount }
                    entry.nextEpisodeTitle = nextEpisodeToAir?.name
                    entry.nextEpisodeCode = nextEpisodeToAir?.displayCode
                    entry.nextEpisodeAirDate = nextEpisodeToAir?.airDate
                }
                entry.isFavorite = true
                modelContext.insert(entry)
            } else {
                entry.isFavorite.toggle()
                entry.dateUpdated = .now
            }

            do {
                try modelContext.save()
                persistenceError = nil
            } catch {
                let saveError = error.localizedDescription
                if let previousFavorite, let previousUpdatedAt {
                    entry.isFavorite = previousFavorite
                    entry.dateUpdated = previousUpdatedAt
                } else {
                    modelContext.delete(entry)
                }
                do {
                    try modelContext.save()
                    persistenceError = saveError
                } catch {
                    persistenceError = "Favoritmarkeringen kunde inte återställas: \(error.localizedDescription)"
                }
            }
        } label: {
            Label(
                isFavorite ? "Ta bort från favoriter" : "Lägg till i favoriter",
                systemImage: isFavorite ? "heart.fill" : "heart"
            )
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(isFavorite ? WatchlistColor.accent : WatchlistColor.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(WatchlistColor.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var addToCustomListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("EGNA SAMLINGAR")
            if customLists.isEmpty {
                NavigationLink {
                    CustomListsView()
                } label: {
                    Label("Skapa en lista", systemImage: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(WatchlistColor.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 12))
                }
            } else {
                Menu {
                    ForEach(customLists) { list in
                        let isSaved = customListItems.contains {
                            $0.listID == list.id && $0.mediaStableID == item.stableID
                        }
                        Button {
                            add(item, to: list)
                        } label: {
                            Label(
                                isSaved ? "\(list.name) · Tillagd" : list.name,
                                systemImage: isSaved ? "checkmark" : "rectangle.stack"
                            )
                        }
                        .disabled(isSaved)
                    }
                } label: {
                    Label("Lägg till i en lista", systemImage: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(WatchlistColor.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func add(_ mediaItem: MediaItem, to list: CustomList) {
        let stableID = "\(list.id)::\(mediaItem.stableID)"
        guard !customListItems.contains(where: { $0.stableID == stableID }) else { return }

        let membership = CustomListItem(listID: list.id, item: mediaItem)
        let previousUpdatedAt = list.updatedAt
        modelContext.insert(membership)
        list.updatedAt = .now

        do {
            try modelContext.save()
            persistenceError = nil
        } catch {
            let saveError = error.localizedDescription
            modelContext.delete(membership)
            list.updatedAt = previousUpdatedAt
            do {
                try modelContext.save()
                persistenceError = saveError
            } catch {
                persistenceError = "Titeln kunde inte läggas till i samlingen efter ett sparfel: \(error.localizedDescription)"
            }
        }
    }

    private var metadata: some View {
        HStack(spacing: 10) {
            if let year = item.releaseDate?.prefix(4), !year.isEmpty {
                metadataText(String(year))
            }
            if item.voteAverage > 0 {
                metadataText("★  " + String(format: "%.1f", item.voteAverage))
            }
        }
        .padding(.horizontal, 20)
    }


    @ViewBuilder
    private var upNextSection: some View {
        if item.kind == .television,
           let lastEpisode = lastEpisodeToAir,
           let nextEpisode = nextEpisodeToAir,
           let nextDate = premiereDate(from: nextEpisode.airDate),
           nextDate >= Calendar.current.startOfDay(for: .now),
           episodeProgressEntries.contains(where: {
               $0.seriesID == item.id &&
               $0.seasonNumber == lastEpisode.seasonNumber &&
               $0.episodeNumber == lastEpisode.episodeNumber &&
               $0.isWatched
           }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "forward.end.fill")
                        .foregroundStyle(WatchlistColor.accent)
                    sectionLabel("UP NEXT")
                    Spacer()
                    Text("NÄSTA AVSNITT")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(1.1)
                        .foregroundStyle(WatchlistColor.mutedText)
                }

                HStack(spacing: 13) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(WatchlistColor.accent.opacity(0.12))
                            .frame(width: 54, height: 62)
                        Image(systemName: "tv")
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(WatchlistColor.accent)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text(nextEpisode.displayCode)
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(WatchlistColor.accent)
                        Text(nextEpisode.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(WatchlistColor.primaryText)
                            .lineLimit(2)
                        Text("Släpps " + nextDate.formatted(.dateTime.locale(Locale(identifier: "sv_SE")).weekday(.wide).day().month(.wide)).capitalized)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(WatchlistColor.secondaryText)
                    }
                    Spacer(minLength: 0)
                }
                .padding(13)
                .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(WatchlistColor.hairline, lineWidth: 1))

                Text("Du har markerat det senast släppta avsnittet som sett.")
                    .font(.system(size: 10))
                    .foregroundStyle(WatchlistColor.mutedText)
            }
            .padding(.horizontal, 20)
        }
    }

    private func premiereDate(from value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }

    @ViewBuilder
    private var televisionSeasonsSection: some View {
        if item.kind == .television {
            VStack(alignment: .leading, spacing: 13) {
                sectionLabel("SÄSONGER OCH AVSNITT")

                if !televisionSeasons.isEmpty {
                    seriesProgressSummary
                }

                if isLoadingSeasons && televisionSeasons.isEmpty {
                    ProgressView("Hämtar säsonger…")
                        .tint(WatchlistColor.accent)
                        .font(.system(size: 12))
                } else if let seasonError {
                    Text(seasonError)
                        .font(.system(size: 12))
                        .foregroundStyle(WatchlistColor.secondaryText)
                } else if televisionSeasons.isEmpty {
                    Text("Ingen säsongsinformation finns tillgänglig.")
                        .font(.system(size: 12))
                        .foregroundStyle(WatchlistColor.secondaryText)
                } else {
                    ForEach(televisionSeasons) { season in
                        seasonRow(season)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var seriesProgressSummary: some View {
        let totalEpisodes = televisionSeasons.reduce(0) { $0 + $1.episodeCount }
        let watchedEpisodes = episodeProgressEntries.filter {
            $0.seriesID == item.id && $0.isWatched
        }.count
        let progress = totalEpisodes > 0
            ? Double(watchedEpisodes) / Double(totalEpisodes)
            : 0

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(watchedEpisodes) av \(totalEpisodes) avsnitt sedda")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WatchlistColor.primaryText)
                Spacer()
                Text("\(Int(progress * 100)) %")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(WatchlistColor.secondaryText)
            }
            ProgressView(value: progress)
                .tint(WatchlistColor.accent)
                .background(WatchlistColor.surfaceElevated)
        }
        .padding(14)
        .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private func seasonRow(_ season: TVSeason) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                Task { await toggleSeason(season) }
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(season.displayName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(WatchlistColor.primaryText)
                        Text(seasonProgressLabel(for: season))
                            .font(.system(size: 10))
                            .foregroundStyle(WatchlistColor.secondaryText)
                    }
                    Spacer()
                    if loadingSeasonNumber == season.seasonNumber {
                        ProgressView()
                            .tint(WatchlistColor.accent)
                    } else {
                        Image(systemName: expandedSeason == season.seasonNumber ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(WatchlistColor.mutedText)
                    }
                }
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expandedSeason == season.seasonNumber {
                if let episodes = episodesBySeason[season.seasonNumber] {
                    VStack(spacing: 0) {
                        ForEach(episodes) { episode in
                            episodeRow(episode)
                            if episode.id != episodes.last?.id {
                                Rectangle()
                                    .fill(WatchlistColor.hairline)
                                    .frame(height: 1)
                            }
                        }
                    }
                    .padding(.bottom, 10)
                } else if loadingSeasonNumber == season.seasonNumber {
                    ProgressView("Hämtar avsnitt…")
                        .tint(WatchlistColor.accent)
                        .font(.system(size: 11))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                } else if let error = seasonEpisodeErrors[season.seasonNumber] {
                    Text("Kunde inte hämta avsnitten. Tryck på säsongen för att försöka igen.\n\(error)")
                        .font(.system(size: 10))
                        .foregroundStyle(WatchlistColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 12)
                }
            }
        }
        .padding(.horizontal, 14)
        .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func episodeRow(_ episode: TVEpisode) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Text(episode.displayCode)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(WatchlistColor.accent)
                .frame(width: 58, alignment: .leading)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(episode.name.isEmpty ? "Avsnitt \(episode.episodeNumber)" : episode.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WatchlistColor.primaryText)
                HStack(spacing: 8) {
                    if let airDate = episode.airDate, !airDate.isEmpty {
                        Text(airDate)
                    }
                    if let runtime = episode.runtime, runtime > 0 {
                        Text("\(runtime) min")
                    }
                }
                .font(.system(size: 9))
                .foregroundStyle(WatchlistColor.mutedText)
                if !episode.overview.isEmpty {
                    Text(episode.overview)
                        .font(.system(size: 10))
                        .foregroundStyle(WatchlistColor.secondaryText)
                        .lineLimit(3)
                }
            }
            Spacer(minLength: 0)

            Button {
                toggleEpisodeProgress(episode)
            } label: {
                Image(systemName: isEpisodeWatched(episode) ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(isEpisodeWatched(episode) ? WatchlistColor.accent : WatchlistColor.mutedText)
                    .frame(width: 34, height: 34)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isEpisodeWatched(episode) ? "Markera som ej sedd" : "Markera som sedd")
            .contextMenu {
                if isEpisodeWatched(episode) {
                    Button {
                        registerEpisodeRewatch(episode)
                    } label: {
                        Label("Registrera omtittning", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
        .padding(.vertical, 10)
    }

    private func registerEpisodeRewatch(_ episode: TVEpisode) {
        let event = EpisodeWatchEvent(seriesID: item.id, episode: episode)
        modelContext.insert(event)

        do {
            try modelContext.save()
            persistenceError = nil
        } catch {
            let saveError = error.localizedDescription
            modelContext.delete(event)
            do {
                try modelContext.save()
                persistenceError = saveError
            } catch {
                persistenceError = "Omtittningen kunde inte återställas efter ett sparfel: \(error.localizedDescription)"
            }
        }
    }

    private func seasonProgressLabel(for season: TVSeason) -> String {
        let watched = episodeProgressEntries.filter {
            $0.seriesID == item.id && $0.seasonNumber == season.seasonNumber && $0.isWatched
        }.count
        return watched == 0
            ? "\(season.episodeCount) avsnitt"
            : "\(season.episodeCount) avsnitt · \(watched) sedda"
    }

    private func isEpisodeWatched(_ episode: TVEpisode) -> Bool {
        let id = EpisodeProgress.makeStableID(
            seriesID: item.id,
            seasonNumber: episode.seasonNumber,
            episodeNumber: episode.episodeNumber
        )
        return episodeProgressEntries.first { $0.stableID == id }?.isWatched ?? false
    }

    private func toggleEpisodeProgress(_ episode: TVEpisode) {
        let id = EpisodeProgress.makeStableID(
            seriesID: item.id,
            seasonNumber: episode.seasonNumber,
            episodeNumber: episode.episodeNumber
        )
        let existingProgress = episodeProgressEntries.first { $0.stableID == id }
        let previousWatched = existingProgress?.isWatched
        let previousWatchedAt = existingProgress?.watchedAt
        let previousUpdatedAt = existingProgress?.dateUpdated
        let shouldMarkWatched = !(existingProgress?.isWatched ?? false)
        let progress = existingProgress ?? EpisodeProgress(
            seriesID: item.id,
            episode: episode,
            isWatched: true
        )
        let event = shouldMarkWatched
            ? EpisodeWatchEvent(seriesID: item.id, episode: episode)
            : nil

        if existingProgress == nil {
            modelContext.insert(progress)
        } else {
            progress.setWatched(shouldMarkWatched)
        }
        if let event {
            modelContext.insert(event)
        }

        do {
            try modelContext.save()
            persistenceError = nil
        } catch {
            let saveError = error.localizedDescription
            if let event {
                modelContext.delete(event)
            }
            if let previousWatched, let previousUpdatedAt {
                progress.isWatched = previousWatched
                progress.watchedAt = previousWatchedAt
                progress.dateUpdated = previousUpdatedAt
            } else {
                modelContext.delete(progress)
            }

            do {
                try modelContext.save()
                persistenceError = saveError
            } catch {
                persistenceError = "Avsnittsstatusen kunde inte återställas efter ett sparfel: \(error.localizedDescription)"
            }
        }
    }

    @MainActor
    private func loadTelevisionSeasons() async {
        guard item.kind == .television, televisionSeasons.isEmpty, !isLoadingSeasons else { return }
        guard TMDBConfiguration.isConfigured else {
            seasonError = "Lägg till din TMDB-token för att visa säsonger och avsnitt."
            return
        }

        isLoadingSeasons = true
        seasonError = nil
        defer { isLoadingSeasons = false }

        do {
            let details = try await TMDBConfiguration.makeClient().televisionDetails(id: item.id)
            televisionSeasons = details.regularSeasons
            nextEpisodeToAir = details.nextEpisodeToAir
            lastEpisodeToAir = details.lastEpisodeToAir
            if let entry = libraryEntry {
                entry.episodeTotalCount = details.regularSeasons.reduce(0) { $0 + $1.episodeCount }
                if let next = details.nextEpisodeToAir {
                    entry.nextEpisodeTitle = next.name
                    entry.nextEpisodeCode = next.displayCode
                    entry.nextEpisodeAirDate = next.airDate
                } else {
                    entry.nextEpisodeTitle = nil
                    entry.nextEpisodeCode = nil
                    entry.nextEpisodeAirDate = nil
                }
                saveChanges()
            }
        } catch {
            seasonError = error.localizedDescription
        }
    }

    @MainActor
    private func toggleSeason(_ season: TVSeason) async {
        if expandedSeason == season.seasonNumber,
           episodesBySeason[season.seasonNumber] != nil {
            expandedSeason = nil
            return
        }

        expandedSeason = season.seasonNumber
        guard episodesBySeason[season.seasonNumber] == nil else { return }

        seasonEpisodeErrors[season.seasonNumber] = nil
        loadingSeasonNumber = season.seasonNumber
        defer { loadingSeasonNumber = nil }

        do {
            let details = try await TMDBConfiguration.makeClient().televisionSeason(
                id: item.id,
                seasonNumber: season.seasonNumber
            )
            episodesBySeason[season.seasonNumber] = details.episodes.sorted {
                $0.episodeNumber < $1.episodeNumber
            }
        } catch {
            seasonEpisodeErrors[season.seasonNumber] = error.localizedDescription
        }
    }

    private var sourceNote: some View {
        HStack(spacing: 7) {
            Image(systemName: "info.circle")
            Text("Titelinformation och betyg tillhandahålls av TMDB.")
        }
        .font(.system(size: 10))
        .foregroundStyle(WatchlistColor.mutedText)
        .padding(.horizontal, 20)
    }

    private func metadataText(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(WatchlistColor.secondaryText)
    }

    private func updatePersonalRating(_ rating: Int?) {
        let existingEntry = libraryEntry
        let previousRating = existingEntry?.personalRating
        let previousUpdatedAt = existingEntry?.dateUpdated
        let entry = existingEntry ?? LibraryEntry(item: item)
        if existingEntry == nil {
            modelContext.insert(entry)
        }
        entry.personalRating = rating
        entry.dateUpdated = .now

        do {
            try modelContext.save()
            persistenceError = nil
        } catch {
            let saveError = error.localizedDescription
            if let previousUpdatedAt {
                entry.personalRating = previousRating
                entry.dateUpdated = previousUpdatedAt
            } else {
                modelContext.delete(entry)
            }
            do {
                try modelContext.save()
                persistenceError = saveError
            } catch {
                persistenceError = "Betyget kunde inte återställas efter ett sparfel: \(error.localizedDescription)"
            }
        }
    }

    private func updatePersonalNotes(_ notes: String) {
        let existingEntry = libraryEntry
        let previousNotes = existingEntry?.personalNotes
        let previousUpdatedAt = existingEntry?.dateUpdated
        let entry = existingEntry ?? LibraryEntry(item: item)
        if existingEntry == nil {
            modelContext.insert(entry)
        }
        entry.personalNotes = notes
        entry.dateUpdated = .now

        do {
            try modelContext.save()
            persistenceError = nil
        } catch {
            let saveError = error.localizedDescription
            if let previousUpdatedAt {
                entry.personalNotes = previousNotes ?? ""
                entry.dateUpdated = previousUpdatedAt
            } else {
                modelContext.delete(entry)
            }
            do {
                try modelContext.save()
                persistenceError = saveError
            } catch {
                persistenceError = "Anteckningen kunde inte återställas efter ett sparfel: \(error.localizedDescription)"
            }
        }
    }

    private func saveChanges() {
        do {
            try modelContext.save()
            persistenceError = nil
        } catch {
            persistenceError = error.localizedDescription
        }
    }

    private func sectionLabel(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 9, weight: .bold))
            .tracking(1.7)
            .foregroundStyle(WatchlistColor.accent)
    }
}


private struct SimilarTitleTile: View {
    let item: MediaItem

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Group {
                if let url = item.posterURL {
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
            .frame(width: 112, height: 158)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(item.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(WatchlistColor.primaryText)
                .lineLimit(2)
                .frame(width: 112, alignment: .leading)
            if item.voteAverage > 0 {
                Label(String(format: "%.1f", item.voteAverage), systemImage: "star.fill")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(WatchlistColor.secondaryText)
            }
        }
        .frame(width: 112, alignment: .leading)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(WatchlistColor.surfaceElevated)
            .overlay {
                Image(systemName: item.kind == .movie ? "film" : "tv")
                    .foregroundStyle(WatchlistColor.mutedText)
            }
    }
}
