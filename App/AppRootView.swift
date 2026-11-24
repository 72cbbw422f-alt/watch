import SwiftUI

struct AppRootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Hem", systemImage: "sparkles")
                }

            SimpleFeatureView(title: "Upptäck", subtitle: "Hitta nästa film- eller serieupplevelse.", symbol: "safari")
                .tabItem {
                    Label("Upptäck", systemImage: "safari")
                }

            SimpleFeatureView(title: "Bibliotek", subtitle: "Allt du vill se och allt du redan sett.", symbol: "square.grid.2x2")
                .tabItem {
                    Label("Bibliotek", systemImage: "square.grid.2x2")
                }

            SimpleFeatureView(title: "Kalender", subtitle: "Premiärer och nya avsnitt samlade på ett ställe.", symbol: "calendar")
                .tabItem {
                    Label("Kalender", systemImage: "calendar")
                }

            SimpleFeatureView(title: "Profil", subtitle: "Dina inställningar och preferenser.", symbol: "person.crop.circle")
                .tabItem {
                    Label("Profil", systemImage: "person.crop.circle")
                }
        }
        .tint(WatchlistColor.accent)
    }
}

struct SimpleFeatureView: View {
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        ZStack {
            WatchlistColor.background.ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(WatchlistColor.accent)
                Text(title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(WatchlistColor.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
        }
    }
}
