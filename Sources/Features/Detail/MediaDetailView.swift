import SwiftUI
import SwiftData

struct MediaDetailView: View {
    let item: MediaItem

    @Environment(\.modelContext) private var modelContext
    @Query private var libraryEntries: [LibraryEntry]
    @State private var persistenceError: String?
    @State private var televisionSeasons: [TVSeason] = []
    @State private var episodesBySeason: [Int: [TVEpisode]] = [:]
    @State private var expandedSeason: Int?
    @State private var isLoadingSeasons = false
    @State private var loadingSeasonNumber: Int?
    @State private var seasonError: String?
    private let tmdbClient = TMDBConfiguration.makeClient()

    var body: some View {
        ZStack {
            WatchlistColor.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    artworkHeader
                    metadata
                    libraryActions
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

    private func favoriteButton(isFavorite: Bool) -> some View {
        Button {
            if let entry = libraryEntry {
                entry.isFavorite.toggle()
                entry.dateUpdated = .now
            } else {
                let entry = LibraryEntry(item: item)
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
                        Text("\(season.episodeCount) avsnitt")
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
        }
        .padding(.vertical, 10)
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
            let details = try await tmdbClient.televisionDetails(id: item.id)
            televisionSeasons = details.regularSeasons
        } catch {
            seasonError = error.localizedDescription
        }
    }

    @MainActor
    private func toggleSeason(_ season: TVSeason) async {
        if expandedSeason == season.seasonNumber {
            expandedSeason = nil
            return
        }

        expandedSeason = season.seasonNumber
        guard episodesBySeason[season.seasonNumber] == nil else { return }

        loadingSeasonNumber = season.seasonNumber
        defer { loadingSeasonNumber = nil }

        do {
            let details = try await tmdbClient.televisionSeason(
                id: item.id,
                seasonNumber: season.seasonNumber
            )
            episodesBySeason[season.seasonNumber] = details.episodes.sorted {
                $0.episodeNumber < $1.episodeNumber
            }
        } catch {
            seasonError = error.localizedDescription
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
