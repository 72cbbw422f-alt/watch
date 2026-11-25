import SwiftUI

struct AppRootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Hem", systemImage: "house.fill")
            }

            NavigationStack {
                DiscoverView()
            }
            .tabItem {
                Label("Upptäck", systemImage: "sparkle.magnifyingglass")
            }

            NavigationStack {
                SimpleFeatureView(title: "Bibliotek", subtitle: "Allt du vill se och allt du redan sett.", symbol: "square.grid.2x2")
            }
            .tabItem {
                Label("Bibliotek", systemImage: "books.vertical.fill")
            }

            NavigationStack {
                SimpleFeatureView(title: "Kalender", subtitle: "Premiärer och nya avsnitt samlade på ett ställe.", symbol: "calendar")
            }
            .tabItem {
                Label("Kalender", systemImage: "calendar")
            }

            NavigationStack {
                SimpleFeatureView(title: "Profil", subtitle: "Dina inställningar och preferenser.", symbol: "person.crop.circle")
            }
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
                    .foregroundStyle(WatchlistColor.primaryText)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(WatchlistColor.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
