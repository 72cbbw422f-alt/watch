import SwiftUI
import SwiftData

@main
struct WatchlistApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .preferredColorScheme(.dark)
                .modelContainer(for: [LibraryEntry.self, EpisodeProgress.self, PremiereReminder.self, CustomList.self, CustomListItem.self])
        }
    }
}
