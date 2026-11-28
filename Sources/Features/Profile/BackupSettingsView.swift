import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BackupSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var document: WatchlistBackupDocument?
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var isAnalyzingImport = false
    @State private var pendingImport: WatchlistBackup?
    @State private var importPreview: WatchlistImportPreview?
    @State private var pendingSeenr: SeenrImportPayload?
    @State private var seenrPreview: SeenrImportPreview?
    @State private var isConfirmingImport = false
    @State private var errorMessage: String?
    @State private var exportedSummary: String?
    @State private var importedSummary: String?

    var body: some View {
        ZStack {
            WatchlistColor.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DATA OCH SÄKERHETSKOPIA")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.8)
                            .foregroundStyle(WatchlistColor.accent)
                        Text("Dina uppgifter. Din kontroll.")
                            .font(.system(size: 25, weight: .bold, design: .rounded))
                            .foregroundStyle(WatchlistColor.primaryText)
                        Text("Säkerhetskopiera och flytta ditt bibliotek utan att förlora din personliga tittarhistorik.")
                            .font(.system(size: 13))
                            .foregroundStyle(WatchlistColor.secondaryText)
                    }

                    NavigationLink {
                        TMDBSettingsView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "film.stack")
                                .font(.system(size: 18))
                                .foregroundStyle(WatchlistColor.accent)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Film- och seriedatabas")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(WatchlistColor.primaryText)
                                Text(TMDBConfiguration.isConfigured ? "TMDB är anslutet" : "Anslut TMDB för att aktivera sökningen")
                                    .font(.system(size: 10))
                                    .foregroundStyle(WatchlistColor.secondaryText)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(WatchlistColor.mutedText)
                        }
                        .padding(15)
                        .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 12) {
                        backupRow("Bibliotek", detail: "Status, favoriter, betyg och anteckningar")
                        backupRow("Avsnittsprogress", detail: "Vilka avsnitt som är markerade som sedda")
                        backupRow("Visningshistorik", detail: "Filmvisningar, avsnitt och omtittningar")
                        backupRow("Egna listor", detail: "Listor och deras filmer/serier")
                        backupRow("Premiärpåminnelser", detail: "Sparade datum och påminnelseinställningar")
                    }
                    .padding(16)
                    .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 16))

                    Button(action: prepareExport) {
                        Label("Exportera säkerhetskopia", systemImage: "square.and.arrow.up")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(WatchlistColor.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(WatchlistColor.accent, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    if isAnalyzingImport {
                        HStack(spacing: 10) {
                            ProgressView().tint(WatchlistColor.accent)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Analyserar exporten")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(WatchlistColor.primaryText)
                                Text("Stora Seenr-filer kan ta en liten stund.")
                                    .font(.system(size: 10))
                                    .foregroundStyle(WatchlistColor.secondaryText)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 14))
                    }

                    Button { isImporting = true } label: {
                        Label("Importera säkerhetskopia", systemImage: "square.and.arrow.down")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(WatchlistColor.primaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(WatchlistColor.hairline, lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    if let exportedSummary {
                        Text(exportedSummary).font(.system(size: 11)).foregroundStyle(WatchlistColor.secondaryText)
                    }
                    if let importedSummary {
                        Text(importedSummary).font(.system(size: 11)).foregroundStyle(WatchlistColor.accent)
                    }

                    Text("Format: JSON · Schema v1. Importen visar en sammanfattning innan den genomförs. Befintliga lokala poster skrivs inte över eller tas bort.")
                        .font(.system(size: 10))
                        .foregroundStyle(WatchlistColor.mutedText)
                }
                .padding(20)
            }
        }
        .navigationTitle("Säkerhetskopia")
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(
            isPresented: $isExporting,
            document: document,
            contentType: .json,
            defaultFilename: "watchlist-backup"
        ) { result in
            switch result {
            case .success: exportedSummary = "Säkerhetskopian har exporterats."
            case .failure(let error): errorMessage = error.localizedDescription
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImportSelection(result)
        }
        .confirmationDialog(
            "Importera säkerhetskopia?",
            isPresented: $isConfirmingImport,
            titleVisibility: .visible
        ) {
            Button(pendingSeenr == nil ? "Slå samman med mitt bibliotek" : "Importera Seenr-data", role: .destructive) {
                if pendingSeenr != nil { performSeenrImport() } else { performImport() }
            }
            Button("Avbryt", role: .cancel) {
                pendingImport = nil; importPreview = nil
                pendingSeenr = nil; seenrPreview = nil
            }
        } message: {
            if let seenrPreview {
                Text("Seenr-export · \(pendingSeenr?.totalTitles ?? 0) titlar. Nya titlar: \(seenrPreview.newTitles). Befintliga titlar lämnas orörda: \(seenrPreview.matchingTitles). Nya avsnittsstatusar: \(seenrPreview.newEpisodeStates). Avsnittshändelser: \(seenrPreview.newEpisodeHistory). Säsongs- och avsnittsbetyg: \(seenrPreview.newImportedRatings). Filmvisningar: \(seenrPreview.newMovieHistory). Överhoppade titlar: \(seenrPreview.skippedTitles). \(seenrPreview.warnings.isEmpty ? "" : "Varningar: " + seenrPreview.warnings.prefix(3).joined(separator: " "))")
            } else if let importPreview {
                Text("Nya titlar: \(importPreview.newLibraryItems). Matchande titlar lämnas orörda: \(importPreview.matchingLibraryItems). Lokala titlar som bara finns på den här enheten bevaras: \(importPreview.localOnlyLibraryItems). Nya avsnittstillstånd: \(importPreview.newEpisodeStates). Seriehändelser: \(importPreview.newHistoryEvents). Filmhändelser: \(importPreview.newMovieHistoryEvents). Egna listor: \(importPreview.newCustomLists). Listposter: \(importPreview.newCustomListItems). Påminnelser: \(importPreview.newReminders).")
            }
        }
        .alert("Säkerhetskopiering", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Ett oväntat fel uppstod.")
        }
    }

    private func backupRow(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(WatchlistColor.primaryText)
            Text(detail).font(.system(size: 10)).foregroundStyle(WatchlistColor.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func prepareExport() {
        do {
            let backup = try WatchlistBackupService.makeBackup(from: modelContext)
            document = WatchlistBackupDocument(data: try WatchlistBackupService.encode(backup))
            exportedSummary = nil
            isExporting = true
        } catch { errorMessage = error.localizedDescription }
    }

    private enum ImportFileAnalysis: Sendable {
        case seenr(SeenrImportPayload)
        case watchlistBackup(Data)
    }

    private func handleImportSelection(_ result: Result<[URL], Error>) {
        do {
            let urls = try result.get()
            guard let url = urls.first else { return }
            let hasAccess = url.startAccessingSecurityScopedResource()
            isAnalyzingImport = true

            Task {
                defer {
                    if hasAccess { url.stopAccessingSecurityScopedResource() }
                    isAnalyzingImport = false
                }

                do {
                    let analysis = try await Task.detached(priority: .userInitiated) {
                        let data = try Data(contentsOf: url)
                        let isSeenr = String(data: data.prefix(2_000), encoding: .utf8)?
                            .contains("seenr-export/2") == true
                        if isSeenr {
                            return ImportFileAnalysis.seenr(try SeenrExportDecoder.decode(data))
                        }
                        return ImportFileAnalysis.watchlistBackup(data)
                    }.value

                    switch analysis {
                    case .seenr(let payload):
                        let preview = try SeenrImportService.preview(payload, in: modelContext)
                        pendingSeenr = payload
                        seenrPreview = preview
                        pendingImport = nil
                        importPreview = nil
                    case .watchlistBackup(let data):
                        let backup = try WatchlistBackupService.decode(data)
                        let preview = try WatchlistImportService.preview(backup, in: modelContext)
                        pendingImport = backup
                        importPreview = preview
                        pendingSeenr = nil
                        seenrPreview = nil
                    }
                    isConfirmingImport = true
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func performImport() {
        guard let pendingImport else { return }
        do {
            let existingReminderIDs = Set(try modelContext.fetch(FetchDescriptor<PremiereReminder>()).map(\.stableID))
            let reminderIDs = WatchlistImportService.reminderIDsToSchedule(
                from: pendingImport,
                existingReminderIDs: existingReminderIDs
            )
            let summary = try WatchlistImportService.merge(pendingImport, into: modelContext)
            self.pendingImport = nil
            importPreview = nil
            importedSummary = "Import klar. \(summary.newLibraryItems) nya titlar och \(summary.newHistoryEvents + summary.newMovieHistoryEvents) historikhändelser har lagts till. Befintliga poster behölls."
            restoreImportedNotifications(withIDs: reminderIDs)
        } catch { errorMessage = error.localizedDescription }
    }


    private func performSeenrImport() {
        guard let pendingSeenr else { return }
        do {
            let summary = try SeenrImportService.merge(pendingSeenr, into: modelContext)
            self.pendingSeenr = nil
            seenrPreview = nil
            importedSummary = "Seenr-import klar. \(summary.newTitles) nya titlar, \(summary.newEpisodeStates) avsnittsstatusar och \(summary.newEpisodeHistory + summary.newMovieHistory) visningshändelser och \(summary.newImportedRatings) säsongs-/avsnittsbetyg har lagts till. Befintliga poster behölls."
            if !summary.warnings.isEmpty {
                importedSummary? += " Varningar: " + summary.warnings.joined(separator: " ")
            }
        } catch { errorMessage = error.localizedDescription }
    }

    private func restoreImportedNotifications(withIDs stableIDs: Set<String>) {
        guard !stableIDs.isEmpty else { return }
        do {
            let reminders = try modelContext.fetch(FetchDescriptor<PremiereReminder>())
                .filter { stableIDs.contains($0.stableID) }
            Task {
                var scheduledCount = 0
                var unavailableCount = 0
                for reminder in reminders {
                    do {
                        if try await PremiereNotificationService.scheduleIfAuthorized(reminder) {
                            scheduledCount += 1
                        } else {
                            unavailableCount += 1
                        }
                    } catch {
                        // The reminder record remains imported; explain that its notification was skipped.
                        unavailableCount += 1
                    }
                }

                var notificationSummary: [String] = []
                if scheduledCount > 0 {
                    notificationSummary.append("\(scheduledCount) notiser schemalagda")
                }
                if unavailableCount > 0 {
                    notificationSummary.append("\(unavailableCount) påminnelser sparade utan aktiv notis. Kontrollera notisbehörighet och premiärdatum.")
                }
                if !notificationSummary.isEmpty {
                    importedSummary = (importedSummary ?? "Import klar.") + " " + notificationSummary.joined(separator: ". ") + "."
                }
            }
        } catch {
            errorMessage = "Importen sparades, men påminnelserna kunde inte läsas in."
        }
    }
}
