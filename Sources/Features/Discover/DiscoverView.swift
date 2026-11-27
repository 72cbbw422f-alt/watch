import SwiftUI

struct DiscoverView: View {
    @State private var query = ""
    @State private var selectedKind: MediaKind = .movie
    @State private var results: [MediaItem] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var searchRequestID = UUID()
    @State private var trendingItems: [MediaItem] = []
    @State private var isLoadingTrending = false
    @State private var trendingError: String?
    @FocusState private var searchFocused: Bool

    private var visibleTrendingItems: [MediaItem] {
        trendingItems.filter { $0.kind == selectedKind }
    }

    var body: some View {
        ZStack {
            WatchlistColor.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    searchField
                    mediaPicker

                    if let errorMessage {
                        ContentUnavailableView(
                            "Sökningen kunde inte genomföras",
                            systemImage: "wifi.exclamationmark",
                            description: Text(errorMessage)
                        )
                        .foregroundStyle(WatchlistColor.secondaryText)
                        Spacer()
                    } else if isSearching {
                        ProgressView("Söker hos TMDB…")
                            .tint(WatchlistColor.accent)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        discoveryLanding
                    } else if results.isEmpty {
                        emptyState
                        Spacer()
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(results) { item in
                                NavigationLink(value: item) {
                                    MediaSearchRow(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.bottom, 28)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Klart") { searchFocused = false }
                    .tint(WatchlistColor.accent)
            }
        }
        .navigationDestination(for: MediaItem.self) { item in
            MediaDetailView(item: item)
        }
        .task {
            await loadTrending()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("DIN NÄSTA FAVORIT")
                .font(.system(size: 9, weight: .bold))
                .tracking(2)
                .foregroundStyle(WatchlistColor.accent)
            Text("Upptäck")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .tracking(-0.8)
                .foregroundStyle(WatchlistColor.primaryText)
            Text("Sök bland filmer och serier.")
                .font(.system(size: 13))
                .foregroundStyle(WatchlistColor.secondaryText)
        }
    }

    private var searchField: some View {
        HStack(spacing: 11) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(WatchlistColor.accent)
            TextField("Titel, skådespelare eller sökord", text: $query)
                .font(.system(size: 14))
                .foregroundStyle(WatchlistColor.primaryText)
                .focused($searchFocused)
                .submitLabel(.search)
                .onSubmit { Task { await search() } }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !query.isEmpty {
                Button {
                    searchRequestID = UUID()
                    isSearching = false
                    query = ""
                    results = []
                    errorMessage = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(WatchlistColor.mutedText)
                }
                .accessibilityLabel("Rensa sökning")
            }
        }
        .padding(.horizontal, 15)
        .frame(height: 52)
        .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(WatchlistColor.hairline, lineWidth: 1))
    }

    private var mediaPicker: some View {
        HStack(spacing: 8) {
            kindButton(.movie, title: "Filmer", symbol: "film")
            kindButton(.television, title: "Serier", symbol: "tv")
            Spacer()
            Button {
                Task { await search() }
            } label: {
                Label("Sök", systemImage: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(WatchlistColor.background)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(WatchlistColor.accent, in: Capsule())
            }
            .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearching)
            .opacity(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
        }
    }

    private func kindButton(_ kind: MediaKind, title: String, symbol: String) -> some View {
        Button {
            searchRequestID = UUID()
            isSearching = false
            selectedKind = kind
            results = []
            errorMessage = nil
            if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Task { await search() }
            }
        } label: {
            Label(title, systemImage: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(selectedKind == kind ? WatchlistColor.primaryText : WatchlistColor.secondaryText)
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .background(selectedKind == kind ? WatchlistColor.surfaceElevated : Color.clear, in: Capsule())
                .overlay(Capsule().stroke(selectedKind == kind ? WatchlistColor.hairline : Color.clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var discoveryLanding: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("JUST NU")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(WatchlistColor.accent)
                    Text("Trendande titlar")
                        .font(.system(size: 20, weight: .semibold, design: .serif))
                        .foregroundStyle(WatchlistColor.primaryText)
                }
                Spacer()
                Text("DEN HÄR VECKAN")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(WatchlistColor.mutedText)
            }

            if !TMDBConfiguration.isConfigured {
                VStack(alignment: .leading, spacing: 9) {
                    Label("Anslut TMDB för att upptäcka titlar", systemImage: "film.stack")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(WatchlistColor.primaryText)
                    Text("När databasen är ansluten visas aktuella filmer och serier med affischer, betyg och premiärår här.")
                        .font(.system(size: 12))
                        .foregroundStyle(WatchlistColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 16))
            } else if isLoadingTrending && trendingItems.isEmpty {
                ProgressView()
                    .tint(WatchlistColor.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 35)
            } else if let trendingError, trendingItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Det gick inte att hämta trender")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(WatchlistColor.primaryText)
                    Text(trendingError)
                        .font(.system(size: 11))
                        .foregroundStyle(WatchlistColor.secondaryText)
                    Button("Försök igen") { Task { await loadTrending() } }
                        .font(.system(size: 12, weight: .semibold))
                        .tint(WatchlistColor.accent)
                }
            } else if visibleTrendingItems.isEmpty {
                Text("Inga trendande titlar kunde hämtas just nu.")
                    .font(.system(size: 12))
                    .foregroundStyle(WatchlistColor.secondaryText)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(visibleTrendingItems.prefix(20)) { item in
                            NavigationLink(value: item) {
                                DiscoverPosterTile(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.trailing, 20)
                }
                .contentMargins(.trailing, -20)
            }

            HStack(spacing: 10) {
                Image(systemName: selectedKind == .movie ? "film" : "tv")
                    .font(.system(size: 16))
                    .foregroundStyle(WatchlistColor.accent)
                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedKind == .movie ? "Hitta nästa filmkväll" : "Hitta nästa serie")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(WatchlistColor.primaryText)
                    Text("Sök på titel, skådespelare eller genre")
                        .font(.system(size: 10))
                        .foregroundStyle(WatchlistColor.secondaryText)
                }
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(.top, 4)
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

    private var emptyState: some View {
        let hasSearchTerm = !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        return VStack(spacing: 13) {
            Image(systemName: hasSearchTerm ? "film.slash" : "sparkle.magnifyingglass")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(WatchlistColor.accent)
            Text(hasSearchTerm ? "Inga träffar" : "Vad är du sugen på?")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(WatchlistColor.primaryText)
            Text(hasSearchTerm
                 ? "Vi hittade inga \(selectedKind == .movie ? "filmer" : "serier") för ”\(query)”. Prova en annan titel eller stavning."
                 : "Sök efter en film eller serie och bygg din egen lista.")
                .font(.system(size: 12))
                .foregroundStyle(WatchlistColor.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
            if !TMDBConfiguration.isConfigured {
                Text("TMDB är inte konfigurerat ännu. Lägg till din åtkomsttoken enligt TMDB_SETUP.md.")
                    .font(.system(size: 10))
                    .foregroundStyle(WatchlistColor.warmHighlight)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 62)
    }

    @MainActor
    private func search() async {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            searchFocused = false
            return
        }
        searchFocused = false

        let requestID = UUID()
        let requestedKind = selectedKind
        searchRequestID = requestID
        isSearching = true
        errorMessage = nil

        defer {
            if searchRequestID == requestID {
                isSearching = false
            }
        }

        do {
            let fetchedResults = requestedKind == .movie
                ? try await TMDBConfiguration.makeClient().searchMovies(query: term)
                : try await TMDBConfiguration.makeClient().searchTelevision(query: term)

            // Ignore stale responses if the user cleared the query, changed media type,
            // or started a newer search while this request was in flight.
            guard searchRequestID == requestID else { return }
            results = fetchedResults
        } catch {
            guard searchRequestID == requestID else { return }
            errorMessage = error.localizedDescription
        }
    }
}

private struct MediaSearchRow: View {
    let item: MediaItem

    var body: some View {
        HStack(spacing: 13) {
            poster
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title.isEmpty ? "Okänd titel" : item.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(WatchlistColor.primaryText)
                    .lineLimit(2)
                HStack(spacing: 7) {
                    Text(item.kind.displayName.uppercased())
                    if let year = item.releaseDate?.prefix(4), !year.isEmpty {
                        Text("·")
                        Text(String(year))
                    }
                    if item.voteAverage > 0 {
                        Text("·")
                        Label(String(format: "%.1f", item.voteAverage), systemImage: "star.fill")
                    }
                }
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(WatchlistColor.secondaryText)
                Text(item.overview.isEmpty ? "Ingen beskrivning finns tillgänglig." : item.overview)
                    .font(.system(size: 10))
                    .foregroundStyle(WatchlistColor.secondaryText)
                    .lineLimit(3)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 7)
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
            .frame(width: 64, height: 94)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        } else {
            posterPlaceholder
        }
    }

    private var posterPlaceholder: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(WatchlistColor.surfaceElevated)
            .overlay {
                Image(systemName: item.kind == .movie ? "film" : "tv")
                    .foregroundStyle(WatchlistColor.mutedText)
            }
            .frame(width: 64, height: 94)
    }
}
 
private struct DiscoverPosterTile: View {
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
            .frame(width: 126, height: 184)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            Text(item.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(WatchlistColor.primaryText)
                .lineLimit(2)
                .frame(width: 126, alignment: .leading)
            HStack(spacing: 5) {
                if item.voteAverage > 0 {
                    Label(String(format: "%.1f", item.voteAverage), systemImage: "star.fill")
                }
                if let year = item.releaseDate?.prefix(4), !year.isEmpty {
                    Text(String(year))
                }
            }
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(WatchlistColor.secondaryText)
        }
        .frame(width: 126, alignment: .leading)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 11, style: .continuous)
            .fill(WatchlistColor.surfaceElevated)
            .overlay {
                Image(systemName: item.kind == .movie ? "film" : "tv")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(WatchlistColor.mutedText)
            }
    }
}
