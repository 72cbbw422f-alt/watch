import SwiftUI
import SwiftData

struct LibraryView: View {
    @Query(sort: \LibraryEntry.dateAdded, order: .reverse) private var entries: [LibraryEntry]
    @State private var selectedStatus: LibraryStatus?

    private var filteredEntries: [LibraryEntry] {
        guard let selectedStatus else { return entries }
        return entries.filter { $0.status == selectedStatus }
    }

    var body: some View {
        ZStack {
            WatchlistColor.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    statusFilters
                    if filteredEntries.isEmpty {
                        emptyState
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

    private var statusFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("Alla", isSelected: selectedStatus == nil) {
                    selectedStatus = nil
                }
                ForEach(LibraryStatus.allCases) { status in
                    filterChip(status.title, isSelected: selectedStatus == status) {
                        selectedStatus = status
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func filterChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isSelected ? WatchlistColor.background : WatchlistColor.secondaryText)
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(isSelected ? WatchlistColor.accent : WatchlistColor.surface, in: Capsule())
                .overlay(Capsule().stroke(isSelected ? .clear : WatchlistColor.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "books.vertical")
                .font(.system(size: 35, weight: .light))
                .foregroundStyle(WatchlistColor.accent)
            Text(selectedStatus == nil ? "Ditt bibliotek börjar här" : "Inga titlar i den här kategorin")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(WatchlistColor.primaryText)
            Text(selectedStatus == nil
                 ? "Sök efter filmer och serier och lägg till dem i din personliga samling."
                 : "När du ändrar status på en titel visas den här.")
                .font(.system(size: 12))
                .foregroundStyle(WatchlistColor.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
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
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(WatchlistColor.mutedText)
        }
        .padding(11)
        .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(WatchlistColor.hairline, lineWidth: 1))
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
