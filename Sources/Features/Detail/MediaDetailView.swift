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
    @State private var episodesBySeason: [Int: [TVEpisode]] = [:]
    @State private var expandedSeason: Int?
    @State private var isLoadingSeasons = false
    @State private var loadingSeasonNumber: Int?
    @State private var seasonError: String?
    @State private var seasonEpisodeErrors: [Int: String] = [:]
    @State private var similarItems: [MediaItem] = []
    @State private var isLoadingSimilar = false
    var body: some View {
        ZStack {
            WatchlistColor.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    artworkHeader
                    metadata
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
                                entry.status = status
                                saveChanges()
                            } label: {
                                Label(status.title, systemImage: status.symbol)
                            }
                        }
                        Button(role: .destructive) {
                            modelContext.delete(entry)
                            saveChanges()
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
                Button {
                    let entry = LibraryEntry(item: item)
                    if item.kind == .television && !televisionSeasons.isEmpty {
                        entry.episodeTotalCount = televisionSeasons.reduce(0) { $0 + $1.episodeCount }
                        entry.nextEpisodeTitle = nextEpisodeToAir?.name
                        entry.nextEpisodeCode = nextEpisodeToAir?.displayCode
                        entry.nextEpisodeAirDate = nextEpisodeToAir?.airDate
                    }
                    modelContext.insert(entry)
                    saveChanges()
                } label: {
                    Label("Lägg till i min lista", systemImage: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(WatchlistColor.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(WatchlistColor.accent, in: RoundedRectangle(cornerRadius: 15))
                }
                .buttonStyle(.plain)
                favoriteButton(isFavorite: false)
            }
        }
        .padding(.horizontal, 20)
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
            if let entry = libraryEntry {
                entry.isFavorite.toggle()
                entry.dateUpdated = .now
            } else {
                let entry = LibraryEntry(item: item)
                if item.kind == .television && !televisionSeasons.isEmpty {
                    entry.episodeTotalCount = televisionSeasons.reduce(0) { $0 + $1.episodeCount }
                    entry.nextEpisodeTitle = nextEpisodeToAir?.name
                    entry.nextEpisodeCode = nextEpisodeToAir?.displayCode
                    entry.nextEpisodeAirDate = nextEpisodeToAir?.airDate
                }
                entry.isFavorite = true
                modelContext.insert(entry)
            }
            saveChanges()
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
        modelContext.insert(CustomListItem(listID: list.id, item: mediaItem))
        list.updatedAt = .now
        saveChanges()
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
        modelContext.insert(EpisodeWatchEvent(seriesID: item.id, episode: episode))
        saveChanges()
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
        if let progress = episodeProgressEntries.first(where: { $0.stableID == id }) {
            let shouldMarkWatched = !progress.isWatched
            progress.setWatched(shouldMarkWatched)
            if shouldMarkWatched {
                modelContext.insert(EpisodeWatchEvent(seriesID: item.id, episode: episode))
            }
        } else {
            modelContext.insert(EpisodeProgress(seriesID: item.id, episode: episode, isWatched: true))
            modelContext.insert(EpisodeWatchEvent(seriesID: item.id, episode: episode))
        }
        saveChanges()
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
        let entry: LibraryEntry
        if let existing = libraryEntry {
            entry = existing
        } else {
            entry = LibraryEntry(item: item)
            modelContext.insert(entry)
        }
        entry.personalRating = rating
        entry.dateUpdated = .now
        saveChanges()
    }

    private func updatePersonalNotes(_ notes: String) {
        let entry: LibraryEntry
        if let existing = libraryEntry {
            entry = existing
        } else {
            entry = LibraryEntry(item: item)
            modelContext.insert(entry)
        }
        entry.personalNotes = notes
        entry.dateUpdated = .now
        saveChanges()
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
