import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            WatchlistColor.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    hero
                    continueWatching
                    watchlistPreview
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 36)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("DIN FILMVÄRLD")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(2.4)
                    .foregroundStyle(WatchlistColor.accent)
                Text("WATCHLIST")
                    .font(.system(size: 27, weight: .black, design: .rounded))
                    .tracking(-0.8)
                    .foregroundStyle(.white)
            }

            Spacer()

            Button {} label: {
                Image(systemName: "bell")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.07), in: Circle())
                    .overlay(alignment: .topTrailing) {
                        Circle()
                            .fill(WatchlistColor.accent)
                            .frame(width: 7, height: 7)
                            .offset(x: -3, y: 3)
                    }
            }
            .accessibilityLabel("Notiser")
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.25, green: 0.31, blue: 0.35),
                            Color(red: 0.10, green: 0.14, blue: 0.17),
                            Color(red: 0.04, green: 0.05, blue: 0.07)
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                )

            Circle()
                .fill(WatchlistColor.accent.opacity(0.16))
                .frame(width: 220, height: 220)
                .blur(radius: 48)
                .offset(x: 180, y: -130)

            VStack(alignment: .leading, spacing: 12) {
                Text("DIN NÄSTA BESATTHET")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(WatchlistColor.accent)

                Text("Hitta något\nvärt att känna.")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .tracking(-0.8)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Filmerna du längtar efter. Serierna du följer. Allt på ett ställe.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineSpacing(3)
                    .frame(maxWidth: 260, alignment: .leading)

                HStack(spacing: 8) {
                    Image(systemName: "sparkle")
                    Text("Utforska universumet")
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(WatchlistColor.background)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(WatchlistColor.accent, in: Capsule())
                .padding(.top, 6)
            }
            .padding(24)
        }
        .frame(height: 350)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var continueWatching: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Fortsätt där du slutade", eyebrow: "DIN RESA")
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(WatchlistColor.elevated.gradient)
                    .frame(width: 76, height: 96)
                    .overlay {
                        Image(systemName: "play.rectangle")
                            .font(.system(size: 24, weight: .light))
                            .foregroundStyle(WatchlistColor.accent.opacity(0.8))
                    }

                VStack(alignment: .leading, spacing: 7) {
                    Text("Ditt nästa avsnitt")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Dina pågående serier visas här")
                        .font(.system(size: 12))
                        .foregroundStyle(WatchlistColor.secondaryText)
                    ProgressView(value: 0.0)
                        .tint(WatchlistColor.accent)
                        .padding(.top, 4)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var watchlistPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("På din lista", eyebrow: "SPARAT FÖR SENARE")
            HStack(spacing: 10) {
                Image(systemName: "bookmark")
                    .foregroundStyle(WatchlistColor.accent)
                Text("Dina sparade filmer och serier samlas här.")
                    .font(.system(size: 13))
                    .foregroundStyle(WatchlistColor.secondaryText)
                Spacer()
            }
            .padding(16)
            .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func sectionHeader(_ title: String, eyebrow: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(eyebrow)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.8)
                .foregroundStyle(WatchlistColor.accent)
            Text(title)
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .tracking(-0.4)
                .foregroundStyle(.white)
        }
    }
}
