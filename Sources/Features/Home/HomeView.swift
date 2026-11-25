import SwiftUI

struct HomeView: View {
    let onExplore: () -> Void

    @State private var selectedFilter = "För dig"
    @State private var trendingItems: [MediaItem] = []
    @State private var isLoadingTrending = false
    @State private var trendingError: String?

    private let filters = ["För dig", "Filmer", "Serier"]

    var body: some View {
        ZStack {
            WatchlistColor.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 30) {
                    header
                    featured
                    quickFilters
                    continueWatching
                    trending
                    premieres
                    comingSoon
                }
                .padding(.top, 10)
                .padding(.bottom, 34)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await loadTrending() }
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

            Button {} label: {
                Image(systemName: "bell")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(WatchlistColor.primaryText)
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.055), in: Circle())
                    .overlay(alignment: .topTrailing) {
                        Circle().fill(WatchlistColor.accent)
                            .frame(width: 7, height: 7)
                            .overlay(Circle().stroke(WatchlistColor.background, lineWidth: 2))
                            .offset(x: -5, y: 5)
                    }
                    .overlay(Circle().stroke(WatchlistColor.hairline, lineWidth: 1))
            }
            .accessibilityLabel("Notiser")
        }
        .padding(.horizontal, 20)
    }

    private var featured: some View {
        ZStack(alignment: .bottomLeading) {
            GeometryReader { proxy in
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(hex: 0x4A3328),
                            Color(hex: 0x211A17),
                            Color(hex: 0x0E0D0C),
                            Color(hex: 0x080808)
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )

                    Circle()
                        .fill(Color(hex: 0xF47721).opacity(0.25))
                        .frame(width: 210, height: 210)
                        .blur(radius: 48)
                        .offset(x: proxy.size.width * 0.30, y: -85)

                    Ellipse()
                        .fill(Color(hex: 0x7B4A2D).opacity(0.20))
                        .frame(width: 300, height: 130)
                        .blur(radius: 36)
                        .rotationEffect(.degrees(-22))
                        .offset(x: 100, y: -8)

                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "sparkles")
                                .font(.system(size: 58, weight: .ultraLight))
                                .foregroundStyle(.white.opacity(0.18))
                                .padding(.top, 28)
                                .padding(.trailing, 28)
                        }
                        Spacer()
                    }
                }
            }

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.05),
                    .init(color: .black.opacity(0.22), location: 0.38),
                    .init(color: .black.opacity(0.88), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 7) {
                    Circle().fill(WatchlistColor.accent).frame(width: 6, height: 6)
                    Text("UTVALT FÖR DIG")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.9)
                        .foregroundStyle(WatchlistColor.accent)
                }

                Text("Stora berättelser.\nEn plats att samla dem.")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .tracking(-0.8)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Hitta nästa film att älska eller serien du inte kan sluta följa.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.76))
                    .lineSpacing(3)
                    .frame(maxWidth: 285, alignment: .leading)

                Button(action: onExplore) {
                    HStack(spacing: 9) {
                        Text("Utforska")
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(WatchlistColor.background)
                    .padding(.horizontal, 17)
                    .padding(.vertical, 12)
                    .background(WatchlistColor.accent, in: Capsule())
                }
                .padding(.top, 4)
            }
            .padding(23)
        }
        .frame(height: 390)
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 25, style: .continuous).stroke(.white.opacity(0.12), lineWidth: 1))
        .padding(.horizontal, 16)
    }

    private var quickFilters: some View {
        HStack(spacing: 9) {
            ForEach(filters, id: \.self) { filter in
                Button {
                    withAnimation(.snappy(duration: 0.22)) { selectedFilter = filter }
                } label: {
                    Text(filter)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(selectedFilter == filter ? WatchlistColor.background : WatchlistColor.secondaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background {
                            Capsule().fill(selectedFilter == filter ? WatchlistColor.accent : WatchlistColor.surface)
                        }
                        .overlay(Capsule().stroke(selectedFilter == filter ? .clear : WatchlistColor.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
    }

    private var continueWatching: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeading("Fortsätt titta", eyebrow: "DIN RESA", trailing: "Visa alla")
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(LinearGradient(colors: [Color(hex: 0x59636B), Color(hex: 0x171D24)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .frame(width: 74, height: 94)

                VStack(alignment: .leading, spacing: 7) {
                    Text("Din serie väntar")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(WatchlistColor.primaryText)
                    Text("Dina pågående serier visas här")
                        .font(.system(size: 11))
                        .foregroundStyle(WatchlistColor.secondaryText)
                    HStack {
                        Text("AVSNITTSSTATUS")
                            .font(.system(size: 8, weight: .bold))
                            .tracking(1.1)
                            .foregroundStyle(WatchlistColor.mutedText)
                        Spacer()
                        Text("—")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(WatchlistColor.accent)
                    }
                    Capsule().fill(.white.opacity(0.10)).frame(height: 3)
                }
                Spacer(minLength: 0)
            }
            .padding(13)
            .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(WatchlistColor.hairline, lineWidth: 1))
        }
        .padding(.horizontal, 20)
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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 13) {
                        ForEach(trendingItems.prefix(12), id: \.stableID) { item in
                            MediaPosterTile(item: item, rank: (trendingItems.firstIndex(of: item) ?? 0) + 1)
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

        do {
            trendingItems = try await TMDBConfiguration.makeClient().trendingThisWeek()
        } catch {
            trendingError = error.localizedDescription
        }
    }

    private var premieres: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeading("Premiärer att hålla koll på", eyebrow: "KOMMER SNART", trailing: "Kalender")
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(WatchlistColor.accent)
                    .frame(width: 42, height: 42)
                    .background(WatchlistColor.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dina kommande premiärer")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(WatchlistColor.primaryText)
                    Text("Här samlas premiärer för filmer och serier du följer.")
                        .font(.system(size: 10))
                        .foregroundStyle(WatchlistColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(WatchlistColor.hairline, lineWidth: 1))
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
            Button(trailing) {}
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(WatchlistColor.secondaryText)
        }
        .padding(.horizontal, 20)
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
