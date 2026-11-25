import SwiftUI
import SwiftData

struct PremiereCalendarView: View {
    @State private var events: [PremiereEvent] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var reminderError: String?
    @Environment(\.modelContext) private var modelContext
    @Query private var savedReminders: [PremiereReminder]
    private let client = TMDBConfiguration.makeClient()

    private var groupedEvents: [(date: Date, events: [PremiereEvent])] {
        let groups = Dictionary(grouping: events) { Calendar.current.startOfDay(for: $0.date) }
        return groups.keys.sorted().map { date in
            (date, groups[date, default: []].sorted { $0.item.title < $1.item.title })
        }
    }

    var body: some View {
        ZStack {
            WatchlistColor.background.ignoresSafeArea()

            Group {
                if isLoading && events.isEmpty {
                    ProgressView("Hämtar premiärer…")
                        .tint(WatchlistColor.accent)
                } else if let errorMessage, events.isEmpty {
                    emptyState(
                        title: "Kunde inte hämta premiärer",
                        message: errorMessage,
                        symbol: "wifi.exclamationmark"
                    )
                } else if events.isEmpty {
                    emptyState(
                        title: "Inga kommande datum",
                        message: "TMDB har inga kommande svenska premiärdatum att visa just nu.",
                        symbol: "calendar"
                    )
                } else {
                    List {
                        ForEach(groupedEvents, id: \.date) { group in
                            Section {
                                ForEach(group.events) { event in
                                    HStack(spacing: 8) {
                                        NavigationLink(value: event.item) {
                                            PremiereCalendarRow(event: event)
                                        }
                                        .buttonStyle(.plain)
                                        Menu {
                                            if let saved = savedReminders.first(where: { $0.stableID == event.item.stableID }) {
                                                Section("Ändra påminnelse") {
                                                    Button("En vecka före") {
                                                        Task { await addReminder(for: event, leadDays: 7) }
                                                    }
                                                    Button("Dagen före") {
                                                        Task { await addReminder(for: event, leadDays: 1) }
                                                    }
                                                    Button("Samma dag") {
                                                        Task { await addReminder(for: event, leadDays: 0) }
                                                    }
                                                }
                                                Button(role: .destructive) {
                                                    removeReminder(saved)
                                                } label: {
                                                    Label("Ta bort påminnelse", systemImage: "bell.slash")
                                                }
                                            } else {
                                                Section("Påminn mig") {
                                                    Button("En vecka före") {
                                                        Task { await addReminder(for: event, leadDays: 7) }
                                                    }
                                                    Button("Dagen före") {
                                                        Task { await addReminder(for: event, leadDays: 1) }
                                                    }
                                                    Button("Samma dag") {
                                                        Task { await addReminder(for: event, leadDays: 0) }
                                                    }
                                                }
                                            }
                                        } label: {
                                            Image(systemName: savedReminders.contains(where: { $0.stableID == event.item.stableID }) ? "bell.badge.fill" : "bell")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundStyle(WatchlistColor.accent)
                                                .frame(width: 36, height: 44)
                                                .contentShape(Rectangle())
                                        }
                                        .accessibilityLabel("Påminnelse för \(event.item.title)")
                                    }
                                    .listRowBackground(WatchlistColor.surface)
                                    .listRowSeparatorTint(WatchlistColor.hairline)
                                }
                            } header: {
                                Text(group.date.formatted(
                                    .dateTime.locale(Locale(identifier: "sv_SE")).weekday(.wide).day().month(.wide)
                                ).uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1.2)
                                .foregroundStyle(WatchlistColor.accent)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.insetGrouped)
                }
            }
        }
        .navigationTitle("Premiärkalender")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await loadEvents() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(WatchlistColor.secondaryText)
                }
                .accessibilityLabel("Uppdatera premiärer")
            }
        }
        .navigationDestination(for: MediaItem.self) { item in
            MediaDetailView(item: item)
        }
        .task { await loadEvents() }
        .alert("Kunde inte skapa påminnelse", isPresented: Binding(
            get: { reminderError != nil },
            set: { if !$0 { reminderError = nil } }
        )) {
            Button("OK", role: .cancel) { reminderError = nil }
        } message: {
            Text(reminderError ?? "Ett oväntat fel uppstod.")
        }
    }

    @MainActor
    private func loadEvents() async {
        guard TMDBConfiguration.isConfigured else {
            errorMessage = "Lägg till din TMDB-token för att visa premiärdatum."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let movies = client.upcomingMovies()
            async let television = client.upcomingTelevisionPremieres()
            let fetched = try await (movies, television)
            let today = Calendar.current.startOfDay(for: .now)

            let movieEvents: [PremiereEvent] = fetched.0.compactMap { item in
                PremiereEvent(item: item)
            }
            let televisionEvents: [PremiereEvent] = fetched.1.compactMap { item in
                PremiereEvent(item: item)
            }
            let datedEvents = movieEvents + televisionEvents
            events = datedEvents
                .filter { event in event.date >= today }
                .sorted { first, second in first.date < second.date }
            await reconcileReminderDates()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func reconcileReminderDates() async {
        for reminder in savedReminders {
            guard let matchingEvent = events.first(where: { $0.item.stableID == reminder.stableID }),
                  Calendar.current.isDate(matchingEvent.date, inSameDayAs: reminder.premiereDate) == false else {
                continue
            }

            let previousDate = reminder.premiereDate
            reminder.premiereDate = matchingEvent.date
            do {
                // Persist the new date before replacing the pending notification.
                try modelContext.save()
                try await PremiereNotificationService.schedule(reminder)
            } catch {
                reminder.premiereDate = previousDate
                do {
                    try modelContext.save()
                } catch {
                    reminderError = "Datumet för \(reminder.title) kunde inte återställas efter ett sparfel: \(error.localizedDescription)"
                    continue
                }
                reminderError = "Datumet för \(reminder.title) har ändrats, men påminnelsen kunde inte uppdateras: \(error.localizedDescription)"
            }
        }
    }

    @MainActor
    private func addReminder(for event: PremiereEvent, leadDays: Int) async {
        let reminder = PremiereReminder(item: event.item, premiereDate: event.date, leadDays: leadDays)
        if let existing = savedReminders.first(where: { $0.stableID == event.item.stableID }) {
            let previousDate = existing.premiereDate
            let previousLeadDays = existing.leadDays
            let previousTitle = existing.title
            let previousTMDBID = existing.tmdbID
            let previousMediaKind = existing.mediaKind

            existing.premiereDate = event.date
            existing.leadDays = leadDays
            existing.title = event.item.title
            existing.tmdbID = event.item.id
            existing.mediaKind = event.item.kind.rawValue

            do {
                try modelContext.save()
                try await PremiereNotificationService.schedule(existing)
            } catch {
                existing.premiereDate = previousDate
                existing.leadDays = previousLeadDays
                existing.title = previousTitle
                existing.tmdbID = previousTMDBID
                existing.mediaKind = previousMediaKind
                do {
                    try modelContext.save()
                } catch {
                    reminderError = "Påminnelsen kunde inte återställas efter ett sparfel: \(error.localizedDescription)"
                    return
                }
                reminderError = error.localizedDescription
            }
        } else {
            modelContext.insert(reminder)
            do {
                try modelContext.save()
                try await PremiereNotificationService.schedule(reminder)
            } catch {
                modelContext.delete(reminder)
                do {
                    try modelContext.save()
                } catch {
                    reminderError = "Påminnelsen kunde inte tas bort efter ett sparfel: \(error.localizedDescription)"
                    return
                }
                reminderError = error.localizedDescription
            }
        }
    }

    private func removeReminder(_ reminder: PremiereReminder) {
        modelContext.delete(reminder)
        do {
            try modelContext.save()
            PremiereNotificationService.cancel(reminder)
        } catch {
            reminderError = error.localizedDescription
        }
    }

    private func emptyState(title: String, message: String, symbol: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(WatchlistColor.accent)
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(WatchlistColor.primaryText)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(WatchlistColor.secondaryText)
                .multilineTextAlignment(.center)
            if !TMDBConfiguration.isConfigured {
                Text("Konfigurera TMDB i appens bygginställningar.")
                    .font(.system(size: 10))
                    .foregroundStyle(WatchlistColor.mutedText)
            }
        }
        .padding(32)
    }
}

private struct PremiereEvent: Identifiable {
    let item: MediaItem
    let date: Date

    var id: String { item.stableID }

    init?(item: MediaItem) {
        guard
            let rawDate = item.releaseDate,
            let parsedDate = Self.parseDate(rawDate)
        else { return nil }
        self.item = item
        date = parsedDate
    }

    private static func parseDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }
}

private struct PremiereCalendarRow: View {
    let event: PremiereEvent

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(event.date.formatted(.dateTime.locale(Locale(identifier: "sv_SE")).month(.abbreviated)).uppercased())
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(WatchlistColor.accent)
                Text(event.date.formatted(.dateTime.day()))
                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                    .foregroundStyle(WatchlistColor.primaryText)
            }
            .frame(width: 42)

            Group {
                if let url = event.item.posterURL {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            posterPlaceholder
                        }
                    }
                } else {
                    posterPlaceholder
                }
            }
            .frame(width: 42, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(event.item.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WatchlistColor.primaryText)
                    .lineLimit(2)
                Text(event.item.kind.displayName.uppercased())
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(WatchlistColor.mutedText)
                if event.item.voteAverage > 0 {
                    Label(String(format: "%.1f", event.item.voteAverage), systemImage: "star.fill")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(WatchlistColor.secondaryText)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
    }

    private var posterPlaceholder: some View {
        RoundedRectangle(cornerRadius: 7)
            .fill(WatchlistColor.surfaceElevated)
            .overlay {
                Image(systemName: event.item.kind == .movie ? "film" : "tv")
                    .foregroundStyle(WatchlistColor.mutedText)
            }
    }
}
