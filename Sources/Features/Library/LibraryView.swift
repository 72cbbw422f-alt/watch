import SwiftUI
import SwiftData

private enum LibrarySortOrder {
    case recentlyAdded
    case title
    case highestRated
}

struct LibraryView: View {
    @Query(sort: \LibraryEntry.dateAdded, order: .reverse) private var entries: [LibraryEntry]
    @State private var selectedStatus: LibraryStatus?
    @State private var favoritesOnly = false
    @State private var searchText = ""
    @State private var sortOrder = LibrarySortOrder.recentlyAdded
    @State private var usesPosterGrid = true
    @State private var selectedKind: LibraryKindFilter = .all

    private var filteredEntries: [LibraryEntry] {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let matching = entries.filter { entry in
            (selectedStatus == nil || entry.status == selectedStatus)
                && (selectedKind == .all || (selectedKind == .movies ? entry.mediaKind == "movie" : entry.mediaKind == "tv" || entry.mediaKind == "television"))
                && (!favoritesOnly || entry.isFavorite)
                && (term.isEmpty ||
                    entry.title.localizedCaseInsensitiveContains(term) ||
                    entry.personalNotes.localizedCaseInsensitiveContains(term))
        }
        switch sortOrder {
        case .recentlyAdded:
            return matching.sorted {
                if $0.dateAdded != $1.dateAdded { return $0.dateAdded > $1.dateAdded }
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        case .title:
            return matching.sorted {
                let comparison = $0.title.localizedCaseInsensitiveCompare($1.title)
                if comparison != .orderedSame { return comparison == .orderedAscending }
                return $0.dateAdded > $1.dateAdded
            }
        case .highestRated:
            return matching.sorted {
                switch ($0.personalRating, $1.personalRating) {
                case let (first?, second?) where first != second:
                    return first > second
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                default:
                    return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                }
            }
        }
    }

    private var watchedCount: Int {
        entries.filter { $0.status == .watched }.count
    }

    private var watchingCount: Int {
        entries.filter { $0.status == .watching }.count
    }

    private var favoriteCount: Int {
        entries.filter(\.isFavorite).count
    }

    var body: some View {
        ZStack {
            WatchlistColor.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    searchAndSort
                    NavigationLink {
                        CustomListsView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "rectangle.stack")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(WatchlistColor.accent)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Mina listor")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(WatchlistColor.primaryText)
                                Text("Skapa egna samlingar av filmer och serier")
                                    .font(.system(size: 10))
                                    .foregroundStyle(WatchlistColor.secondaryText)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(WatchlistColor.mutedText)
                        }
                        .padding(14)
                        .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 13))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 18)
                    collectionStats
                    mediaKindFilters
                    statusFilters
                    if filteredEntries.isEmpty {
                        if entries.isEmpty {
                            emptyState
                        } else {
                            noResultsState
                        }
                    } else if usesPosterGrid {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], alignment: .leading, spacing: 18) {
                            ForEach(filteredEntries) { entry in
                                NavigationLink(value: entry.mediaItem) {
                                    LibraryPosterTile(entry: entry)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 18)
                    } else {
                        LazyVStack(spacing: 11) {
                            ForEach(filteredEntries) { entry in
                                NavigationLink(value: entry.mediaItem) {
                                    LibraryRow(entry: entry)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 18)
                    }
                }
                .padding(.top, 18)
                .padding(.bottom, 35)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: MediaItem.self) { item in
            MediaDetailView(item: item)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("DIN SAMLING")
                .font(.system(size: 9, weight: .bold))
                .tracking(2)
                .foregroundStyle(WatchlistColor.accent)
            Text("Mitt bibliotek")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .tracking(-0.8)
                .foregroundStyle(WatchlistColor.primaryText)
            Text("\(entries.count) titlar sparade")
                .font(.system(size: 12))
                .foregroundStyle(WatchlistColor.secondaryText)
        }
        .padding(.horizontal, 20)
    }

    
    private var searchAndSort: some View {
        HStack(spacing: 10) {
            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(WatchlistColor.accent)
                TextField("Sök i ditt bibliotek", text: $searchText)
                    .font(.system(size: 12))
                    .foregroundStyle(WatchlistColor.primaryText)
                    .autocorrectionDisabled()
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(WatchlistColor.mutedText)
                    }
                    .accessibilityLabel("Rensa sökning")
                }
            }
            .padding(.horizontal, 13)
            .frame(height: 44)
            .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(WatchlistColor.hairline, lineWidth: 1))

            HStack(spacing: 5) {
                Button {
                    withAnimation(.snappy(duration: 0.2)) { usesPosterGrid = true }
                } label: {
                    Image(systemName: "square.grid.3x3.fill")
                        .foregroundStyle(usesPosterGrid ? WatchlistColor.accent : WatchlistColor.secondaryText)
                        .frame(width: 36, height: 44)
                }
                .accessibilityLabel("Visa affischrutnät")
                .accessibilityValue(usesPosterGrid ? "Vald" : "Inte vald")
                Button {
                    withAnimation(.snappy(duration: 0.2)) { usesPosterGrid = false }
                } label: {
                    Image(systemName: "list.bullet")
                        .foregroundStyle(!usesPosterGrid ? WatchlistColor.accent : WatchlistColor.secondaryText)
                        .frame(width: 32, height: 44)
                }
                .accessibilityLabel("Visa listvy")
                .accessibilityValue(!usesPosterGrid ? "Vald" : "Inte vald")
            }
            .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(WatchlistColor.hairline, lineWidth: 1))

            Menu {
                Button {
                    sortOrder = .recentlyAdded
                } label: {
                    Label("Senast tillagda", systemImage: sortOrder == .recentlyAdded ? "checkmark" : "clock")
                }
                Button {
                    sortOrder = .title
                } label: {
                    Label("Titel A–Ö", systemImage: sortOrder == .title ? "checkmark" : "textformat")
                }
                Button {
                    sortOrder = .highestRated
                } label: {
                    Label("Högst betyg", systemImage: sortOrder == .highestRated ? "checkmark" : "star")
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(WatchlistColor.primaryText)
                    .frame(width: 44, height: 44)
                    .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(WatchlistColor.hairline, lineWidth: 1))
            }
            .accessibilityLabel("Sortera bibliotek")
        }
        .padding(.horizontal, 18)
    }

    private var collectionStats: some View {
        HStack(alignment: .center, spacing: 0) {
            statistic(value: watchedCount, label: "SEDDA")
            statDivider
            statistic(value: watchingCount, label: "PÅGÅR")
            statDivider
            statistic(value: favoriteCount, label: "FAVORITER")
        }
        .padding(.vertical, 15)
        .background(WatchlistColor.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 18)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(WatchlistColor.hairline)
            .frame(width: 1, height: 34)
    }

    private func statistic(value: Int, label: String) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Text("\(value)")
                .font(.system(size: 21, weight: .semibold, design: .rounded))
                .foregroundStyle(WatchlistColor.primaryText)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(WatchlistColor.mutedText)
        }
        .frame(maxWidth: .infinity)
    }

    private var mediaKindFilters: some View {
        HStack(spacing: 8) {
            kindChip("Allt", kind: .all)
            kindChip("Filmer", kind: .movies)
            kindChip("Serier", kind: .series)
            Spacer(minLength: 0)
            Text("\(filteredEntries.count) TITLAR")
                .font(.system(size: 8, weight: .bold))
                .tracking(0.9)
                .foregroundStyle(WatchlistColor.mutedText)
        }
        .padding(.horizontal, 20)
    }

    private func kindChip(_ title: String, kind: LibraryKindFilter) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.2)) { selectedKind = kind }
        } label: {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(selectedKind == kind ? WatchlistColor.primaryText : WatchlistColor.secondaryText)
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(selectedKind == kind ? WatchlistColor.accent.opacity(0.16) : WatchlistColor.surface, in: Capsule())
                .overlay(Capsule().stroke(selectedKind == kind ? WatchlistColor.accent.opacity(0.45) : WatchlistColor.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selectedKind == kind ? .isSelected : [])
    }

    private var statusFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("Alla", isSelected: selectedStatus == nil && !favoritesOnly) {
                    selectedStatus = nil
                }
                ForEach(LibraryStatus.allCases) { status in
                    filterChip(status.title, isSelected: selectedStatus == status && !favoritesOnly) {
                        selectedStatus = status
                        favoritesOnly = false
                    }
                }
                filterChip("Favoriter", isSelected: favoritesOnly) {
                    favoritesOnly.toggle()
                    if favoritesOnly { selectedStatus = nil }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func filterChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isSelected ? WatchlistColor.primaryText : WatchlistColor.secondaryText)
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(isSelected ? WatchlistColor.surfaceElevated : Color.clear, in: Capsule())
                .overlay(Capsule().stroke(isSelected ? WatchlistColor.accent.opacity(0.38) : WatchlistColor.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var noResultsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 35, weight: .light))
                .foregroundStyle(WatchlistColor.accent)
            Text("Inga titlar hittades")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(WatchlistColor.primaryText)
            Text("Prova att ändra sökning eller filter. Dina sparade titlar finns kvar i biblioteket.")
                .font(.system(size: 12))
                .foregroundStyle(WatchlistColor.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            Button {
                searchText = ""
                selectedStatus = nil
                favoritesOnly = false
                selectedKind = .all
            } label: {
                Text("Rensa sökning och filter")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WatchlistColor.accent)
                    .padding(.top, 4)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 38)
        .padding(.vertical, 65)
    }

    private var emptyState: some View {
        let searching = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let title = searching
            ? "Inga matchningar"
            : selectedStatus == nil && !favoritesOnly
                ? "Ditt bibliotek börjar här"
                : favoritesOnly ? "Inga favoriter ännu" : "Inga titlar i den här kategorin"
        let message = searching
            ? "Vi hittar ingen titel eller anteckning som matchar ”\(searchText)”. Prova ett annat sökord."
            : selectedStatus == nil && !favoritesOnly
                ? "Sök efter filmer och serier och lägg till dem i din personliga samling."
                : favoritesOnly ? "Tryck på hjärtat på en titel för att spara den som favorit."
                : "När du ändrar status på en titel visas den här."

        return VStack(spacing: 12) {
            Image(systemName: searching ? "magnifyingglass" : "books.vertical")
                .font(.system(size: 35, weight: .light))
                .foregroundStyle(WatchlistColor.accent)
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(WatchlistColor.primaryText)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(WatchlistColor.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            if searching {
                Button("Rensa sökning") { searchText = "" }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WatchlistColor.accent)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 38)
        .padding(.vertical, 65)
    }
}

private struct LibraryRow: View {
    let entry: LibraryEntry

    var body: some View {
        HStack(spacing: 13) {
            poster
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(WatchlistColor.primaryText)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(entry.mediaKind == "movie" ? "FILM" : "SERIE")
                    if let year = entry.releaseDate?.prefix(4), !year.isEmpty {
                        Text("·")
                        Text(String(year))
                    }
                }
                .font(.system(size: 8, weight: .bold))
                .tracking(1)
                .foregroundStyle(WatchlistColor.mutedText)
                Label(entry.status.title, systemImage: entry.status.symbol)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(WatchlistColor.accent)
                HStack(spacing: 9) {
                    if let rating = entry.personalRating {
                        Label("\(rating)/10", systemImage: "star.fill")
                            .foregroundStyle(WatchlistColor.accent)
                    }
                    if !entry.personalNotes.isEmpty {
                        Label("Anteckning", systemImage: "note.text")
                            .foregroundStyle(WatchlistColor.secondaryText)
                    }
                }
                .font(.system(size: 9, weight: .medium))
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(WatchlistColor.mutedText)
        }
        .padding(.vertical, 7)
    }

    @ViewBuilder
    private var poster: some View {
        if let url = entry.mediaItem.posterURL {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    posterPlaceholder
                }
            }
            .frame(width: 57, height: 82)
            .clipShape(RoundedRectangle(cornerRadius: 9))
        } else {
            posterPlaceholder
        }
    }

    private var posterPlaceholder: some View {
        RoundedRectangle(cornerRadius: 9)
            .fill(WatchlistColor.surfaceElevated)
            .overlay {
                Image(systemName: entry.mediaKind == "movie" ? "film" : "tv")
                    .foregroundStyle(WatchlistColor.mutedText)
            }
            .frame(width: 57, height: 82)
    }
}

private struct LibraryPosterTile: View {
    let entry: LibraryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ZStack(alignment: .topTrailing) {
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
                .frame(maxWidth: .infinity)
                .aspectRatio(2 / 3, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                if entry.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(7)
                        .background(.black.opacity(0.58), in: Circle())
                        .padding(7)
                }
            }

            Text(entry.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(WatchlistColor.primaryText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack(spacing: 4) {
                Circle()
                    .fill(entry.status == .watched ? WatchlistColor.accent : entry.status == .watching ? Color.green : WatchlistColor.mutedText)
                    .frame(width: 5, height: 5)
                Text(entry.status.title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(WatchlistColor.secondaryText)
                Spacer(minLength: 0)
                if let rating = entry.personalRating {
                    Label("\(rating)", systemImage: "star.fill")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(WatchlistColor.accent)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(WatchlistColor.surfaceElevated)
            .overlay {
                Image(systemName: entry.mediaKind == "movie" ? "film" : "tv")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(WatchlistColor.mutedText)
            }
    }
}


private enum LibraryKindFilter {
    case all
    case movies
    case series
}
