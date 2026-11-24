import SwiftUI

struct HomeView: View {
    @State private var selectedFilter = "För dig"

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

            Button {} label: {
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
                            Color(hex: 0x66747B),
                            Color(hex: 0x303B42),
                            Color(hex: 0x10171D),
                            Color(hex: 0x08090B)
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )

                    Circle()
                        .fill(Color(hex: 0xD7C6A0).opacity(0.28))
                        .frame(width: 210, height: 210)
                        .blur(radius: 48)
                        .offset(x: proxy.size.width * 0.30, y: -85)

                    Ellipse()
                        .fill(Color(hex: 0x8A9A9B).opacity(0.22))
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

                Button {} label: {
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
            sectionHeading("Värt att upptäcka", eyebrow: "JUST NU", trailing: "Se allt")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 13) {
                    PosterTile(title: "Dune: Part Two", subtitle: "FILM · SCI-FI", colors: [Color(hex: 0xC18B56), Color(hex: 0x3A2825)], symbol: "sun.max.fill", number: "01")
                    PosterTile(title: "Severance", subtitle: "SERIE · THRILLER", colors: [Color(hex: 0xA9B7B2), Color(hex: 0x263C3A)], symbol: "building.2.fill", number: "02")
                    PosterTile(title: "The Bear", subtitle: "SERIE · DRAMA", colors: [Color(hex: 0xB66C43), Color(hex: 0x35201B)], symbol: "flame.fill", number: "03")
                    PosterTile(title: "The Last of Us", subtitle: "SERIE · DRAMA", colors: [Color(hex: 0x82916B), Color(hex: 0x202A22)], symbol: "leaf.fill", number: "04")
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var premieres: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeading("Snart på skärmen", eyebrow: "KOMMANDE PREMIÄRER", trailing: "Kalender")
            VStack(spacing: 0) {
                PremiereRow(day: "28", month: "NOV", title: "Nya avsnitt väntar", detail: "Premiärer från serier du följer", kind: "AVSNITT")
                Rectangle().fill(WatchlistColor.hairline).frame(height: 1).padding(.leading, 66)
                PremiereRow(day: "02", month: "DEC", title: "Nya filmer på väg", detail: "Filmer på din bevakningslista", kind: "FILM")
            }
            .padding(.horizontal, 14)
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

private struct PosterTile: View {
    let title: String
    let subtitle: String
    let colors: [Color]
    let symbol: String
    let number: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                Circle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 90, height: 90)
                    .blur(radius: 22)
                    .offset(x: 48, y: -82)
                Image(systemName: symbol)
                    .font(.system(size: 42, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.62))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(15)
                LinearGradient(colors: [.clear, .black.opacity(0.58)], startPoint: .center, endPoint: .bottom)
                Text(number)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(12)
            }
            .frame(width: 132, height: 184)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(.white.opacity(0.10), lineWidth: 1))

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(WatchlistColor.primaryText)
                .lineLimit(1)
            Text(subtitle)
                .font(.system(size: 8, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(WatchlistColor.mutedText)
                .lineLimit(1)
        }
        .frame(width: 132, alignment: .leading)
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
