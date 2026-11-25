import SwiftUI

struct DiscoverView: View {
    @State private var query = ""
    @State private var selectedKind: MediaKind = .movie
    @State private var results: [MediaItem] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @FocusState private var searchFocused: Bool

    private let client = TMDBConfiguration.makeClient()

    var body: some View {
        ZStack {
            WatchlistColor.background.ignoresSafeArea()

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
                    ProgressView("Söker i filmbiblioteket…")
                        .tint(WatchlistColor.accent)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if results.isEmpty {
                    emptyState
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
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
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: MediaItem.self) { item in
            MediaDetailView(item: item)
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
            selectedKind = kind
            results = []
            errorMessage = nil
        } label: {
            Label(title, systemImage: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(selectedKind == kind ? WatchlistColor.accent : WatchlistColor.secondaryText)
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .background(selectedKind == kind ? WatchlistColor.accent.opacity(0.10) : WatchlistColor.surface, in: Capsule())
                .overlay(Capsule().stroke(selectedKind == kind ? WatchlistColor.accent.opacity(0.35) : WatchlistColor.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 13) {
            Image(systemName: "sparkle.magnifyingglass")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(WatchlistColor.accent)
            Text("Vad är du sugen på?")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(WatchlistColor.primaryText)
            Text("Sök efter en film eller serie och bygg din egen lista.")
                .font(.system(size: 12))
                .foregroundStyle(WatchlistColor.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 260)
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
        guard !term.isEmpty else { return }

        isSearching = true
        errorMessage = nil
        defer { isSearching = false }

        do {
            results = selectedKind == .movie
                ? try await client.searchMovies(query: term)
                : try await client.searchTelevision(query: term)
        } catch {
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
                .foregroundStyle(WatchlistColor.accent)
                Text(item.overview.isEmpty ? "Ingen beskrivning finns tillgänglig." : item.overview)
                    .font(.system(size: 10))
                    .foregroundStyle(WatchlistColor.secondaryText)
                    .lineLimit(3)
            }
            Spacer(minLength: 0)
        }
        .padding(11)
        .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(WatchlistColor.hairline, lineWidth: 1))
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
