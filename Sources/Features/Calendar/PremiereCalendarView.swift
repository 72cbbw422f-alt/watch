import SwiftUI
import SwiftData

struct PremiereCalendarView: View {
    @State private var events: [PremiereEvent] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var reminderError: String?
    @State private var calendarMode = CalendarMode.agenda
    @State private var displayedMonth = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
    @State private var selectedDate = Calendar.current.startOfDay(for: .now)
    @Environment(\.modelContext) private var modelContext
    @Query private var savedReminders: [PremiereReminder]
    private let client = TMDBConfiguration.makeClient()

    private var groupedEvents: [(date: Date, events: [PremiereEvent])] {
        let groups = Dictionary(grouping: events) { Calendar.current.startOfDay(for: $0.date) }
        return groups.keys.sorted().map { date in
            (date, groups[date, default: []].sorted { $0.item.title < $1.item.title })
        }
    }

    private enum CalendarMode: String, CaseIterable {
        case agenda = "Agenda"
        case month = "Månad"
    }

    private let weekdaySymbols = ["M", "T", "O", "T", "F", "L", "S"]

    private var monthDays: [Date?] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: displayedMonth),
              let dayRange = calendar.range(of: .day, in: .month, for: displayedMonth) else { return [] }
        let weekday = calendar.component(.weekday, from: interval.start)
        let leadingSpaces = (weekday + 5) % 7
        return Array(repeating: nil, count: leadingSpaces) +
            dayRange.compactMap { day -> Date? in calendar.date(byAdding: .day, value: day - 1, to: interval.start) }
                .map { Optional($0) }
    }

    private var selectedDayEvents: [PremiereEvent] {
        events.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
            .sorted { $0.item.title < $1.item.title }
    }

    var body: some View {
        ZStack {
            WatchlistColor.background.ignoresSafeArea()
            Group {
                if isLoading && events.isEmpty {
                    ProgressView("Hämtar premiärer…").tint(WatchlistColor.accent)
                } else if let errorMessage, events.isEmpty {
                    emptyState(title: "Kunde inte hämta premiärer", message: errorMessage, symbol: "wifi.exclamationmark")
                } else if events.isEmpty {
                    emptyState(title: "Inga kommande datum", message: "TMDB har inga kommande svenska premiärdatum att visa just nu.", symbol: "calendar")
                } else {
                    VStack(spacing: 12) {
                        Picker("Kalendervy", selection: $calendarMode) {
                            ForEach(CalendarMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)

                        if calendarMode == .month {
                            monthCalendar
                            Divider().overlay(WatchlistColor.hairline)
                            selectedDayContent
                        } else {
                            agendaContent
                        }
                    }
                }
            }
        }
        .navigationTitle("Premiärkalender")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink {
                    SavedPremiereRemindersView()
                } label: {
                    Image(systemName: "bell")
                        .foregroundStyle(WatchlistColor.accent)
                }
                .accessibilityLabel("Mina påminnelser")
                Button { Task { await loadEvents() } } label: {
                    Image(systemName: "arrow.clockwise").foregroundStyle(WatchlistColor.secondaryText)
                }
                .accessibilityLabel("Uppdatera premiärer")
            }
        }
        .navigationDestination(for: MediaItem.self) { item in MediaDetailView(item: item) }
        .task { await loadEvents() }
        .alert("Kunde inte hantera påminnelse", isPresented: Binding(
            get: { reminderError != nil },
            set: { if !$0 { reminderError = nil } }
        )) {
            Button("OK", role: .cancel) { reminderError = nil }
        } message: {
            Text(reminderError ?? "Ett oväntat fel uppstod.")
        }
    }

    private var monthCalendar: some View {
        VStack(spacing: 14) {
            HStack {
                Button {
                    displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(displayedMonth.formatted(.dateTime.locale(Locale(identifier: "sv_SE")).month(.wide).year()).capitalized)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(WatchlistColor.primaryText)
                Spacer()
                Button {
                    displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                } label: { Image(systemName: "chevron.right") }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(WatchlistColor.accent)
            .padding(.horizontal, 8)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                ForEach(weekdaySymbols.indices, id: \.self) { index in
                    Text(weekdaySymbols[index])
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(WatchlistColor.mutedText)
                        .frame(maxWidth: .infinity)
                }
                ForEach(Array(monthDays.enumerated()), id: \.offset) { entry in
                    if let date = entry.element {
                        let hasEvents = events.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
                        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                        Button { selectedDate = date } label: {
                            VStack(spacing: 4) {
                                Text(date.formatted(.dateTime.day()))
                                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                    .foregroundStyle(isSelected ? WatchlistColor.background : WatchlistColor.primaryText)
                                Circle()
                                    .fill(hasEvents ? (isSelected ? WatchlistColor.background : WatchlistColor.accent) : .clear)
                                    .frame(width: 4, height: 4)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(isSelected ? WatchlistColor.accent : .clear, in: RoundedRectangle(cornerRadius: 8))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(!hasEvents)
                        .opacity(hasEvents ? 1 : 0.42)
                        .accessibilityLabel(date.formatted(date: .complete, time: .omitted) + (hasEvents ? ", premiärer" : ""))
                    } else {
                        Color.clear.frame(height: 34)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    private var selectedDayContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(selectedDate.formatted(.dateTime.locale(Locale(identifier: "sv_SE")).weekday(.wide).day().month(.wide)).capitalized)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(WatchlistColor.primaryText)
                .padding(.horizontal, 16)
            if selectedDayEvents.isEmpty {
                Text("Inga premiärer den här dagen.")
                    .font(.system(size: 12))
                    .foregroundStyle(WatchlistColor.mutedText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(selectedDayEvents) { event in eventRow(event) }
                    }
                    .padding(.horizontal, 12)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var agendaContent: some View {
        List {
            ForEach(groupedEvents, id: \.date) { group in
                Section {
                    ForEach(group.events) { event in eventRow(event) }
                } header: {
                    Text(group.date.formatted(.dateTime.locale(Locale(identifier: "sv_SE")).weekday(.wide).day().month(.wide)).uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(WatchlistColor.accent)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
    }

    private func eventRow(_ event: PremiereEvent) -> some View {
        HStack(spacing: 8) {
            NavigationLink(value: event.item) { PremiereCalendarRow(event: event) }
                .buttonStyle(.plain)
            Menu {
                Section(savedReminders.contains(where: { $0.stableID == event.item.stableID }) ? "Ändra påminnelse" : "Påminn mig") {
                    Button("En vecka före") { Task { await addReminder(for: event, leadDays: 7) } }
                    Button("Dagen före") { Task { await addReminder(for: event, leadDays: 1) } }
                    Button("Samma dag") { Task { await addReminder(for: event, leadDays: 0) } }
                }
                if let saved = savedReminders.first(where: { $0.stableID == event.item.stableID }) {
                    Button(role: .destructive) { removeReminder(saved) } label: {
                        Label("Ta bort påminnelse", systemImage: "bell.slash")
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
        .padding(.horizontal, 8)
        .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 10))
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
            if !events.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }),
               let firstEvent = events.first {
                selectedDate = Calendar.current.startOfDay(for: firstEvent.date)
                displayedMonth = Calendar.current.dateInterval(of: .month, for: firstEvent.date)?.start ?? firstEvent.date
            }
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
            // Restore the model if persistence failed; do not leave the reminder deleted locally.
            modelContext.insert(reminder)
            do {
                try modelContext.save()
            } catch {
                reminderError = "Påminnelsen kunde inte återställas: \(error.localizedDescription)"
                return
            }
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


private struct SavedPremiereRemindersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PremiereReminder.premiereDate, order: .forward) private var reminders: [PremiereReminder]
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            WatchlistColor.background.ignoresSafeArea()
            if reminders.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bell")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(WatchlistColor.accent)
                    Text("Inga sparade påminnelser")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(WatchlistColor.primaryText)
                    Text("Lägg till påminnelser från premiärkalendern.")
                        .font(.system(size: 12))
                        .foregroundStyle(WatchlistColor.secondaryText)
                }
                .padding(32)
            } else {
                List {
                    ForEach(reminders, id: \.stableID) { reminder in
                        HStack(spacing: 12) {
                            Image(systemName: reminder.mediaKind == MediaKind.movie.rawValue ? "film" : "tv")
                                .foregroundStyle(WatchlistColor.accent)
                                .frame(width: 38, height: 44)
                                .background(WatchlistColor.surfaceElevated, in: RoundedRectangle(cornerRadius: 9))
                            VStack(alignment: .leading, spacing: 5) {
                                Text(reminder.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(WatchlistColor.primaryText)
                                    .lineLimit(2)
                                Text(reminder.mediaKind == MediaKind.movie.rawValue ? "FILM" : "SERIE")
                                    .font(.system(size: 8, weight: .bold))
                                    .tracking(1)
                                    .foregroundStyle(WatchlistColor.mutedText)
                                Text(reminder.leadDescription)
                                    .font(.system(size: 10))
                                    .foregroundStyle(WatchlistColor.secondaryText)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(reminder.premiereDate.formatted(.dateTime.locale(Locale(identifier: "sv_SE")).day()))
                                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                                    .foregroundStyle(WatchlistColor.primaryText)
                                Text(reminder.premiereDate.formatted(.dateTime.locale(Locale(identifier: "sv_SE")).month(.abbreviated)).uppercased())
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(WatchlistColor.accent)
                            }
                        }
                        .padding(.vertical, 5)
                        .listRowBackground(WatchlistColor.surface)
                        .listRowSeparatorTint(WatchlistColor.hairline)
                        .swipeActions {
                            Button(role: .destructive) { remove(reminder) } label: {
                                Label("Ta bort", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Mina påminnelser")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Kunde inte ta bort påminnelsen", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Ett oväntat fel uppstod.")
        }
    }

    private func remove(_ reminder: PremiereReminder) {
        modelContext.delete(reminder)
        do {
            try modelContext.save()
            PremiereNotificationService.cancel(reminder)
        } catch {
            modelContext.insert(reminder)
            do { try modelContext.save() }
            catch {
                errorMessage = "Påminnelsen kunde inte återställas: \(error.localizedDescription)"
                return
            }
            errorMessage = error.localizedDescription
        }
    }
}
