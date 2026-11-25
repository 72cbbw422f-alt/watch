import SwiftUI
import SwiftData

struct MediaDetailView: View {
    let item: MediaItem

    @Environment(\.modelContext) private var modelContext
    @Query private var libraryEntries: [LibraryEntry]

    var body: some View {
        ZStack {
            WatchlistColor.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    artworkHeader
                    titleBlock
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
                    if let year = item.releaseDate?.prefix(4), !year.isEmpty {
                        Text(String(year))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(WatchlistColor.secondaryText)
                    }
                    if item.voteAverage > 0 {
                        Label(String(format: "%.1f / 10", item.voteAverage), systemImage: "star.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(WatchlistColor.accent)
                    }
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
                                try? modelContext.save()
                            } label: {
                                Label(status.title, systemImage: status.symbol)
                            }
                        }
                        Button(role: .destructive) {
                            modelContext.delete(entry)
                            try? modelContext.save()
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
                    try? modelContext.save()
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
            } else {
                let entry = LibraryEntry(item: item)
                entry.isFavorite = true
                modelContext.insert(entry)
            }
            try? modelContext.save()
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

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(item.title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(WatchlistColor.primaryText)
            Text(item.kind == .movie ? "Film" : "TV-serie")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(WatchlistColor.secondaryText)
        }
        .padding(.horizontal, 20)
    }

    private var metadata: some View {
        HStack(spacing: 10) {
            metadataPill(item.kind.displayName)
            if let year = item.releaseDate?.prefix(4), !year.isEmpty {
                metadataPill(String(year))
            }
            if item.voteAverage > 0 {
                metadataPill("★  " + String(format: "%.1f", item.voteAverage))
            }
        }
        .padding(.horizontal, 20)
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

    private func metadataPill(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(WatchlistColor.secondaryText)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(WatchlistColor.surface, in: Capsule())
            .overlay(Capsule().stroke(WatchlistColor.hairline, lineWidth: 1))
    }

    private func sectionLabel(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 9, weight: .bold))
            .tracking(1.7)
            .foregroundStyle(WatchlistColor.accent)
    }
}
