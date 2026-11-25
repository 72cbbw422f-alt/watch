import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BackupSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var document: WatchlistBackupDocument?
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var pendingImport: WatchlistBackup?
    @State private var importPreview: WatchlistImportPreview?
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
            Button("Slå samman med mitt bibliotek", role: .destructive) {
                performImport()
            }
            Button("Avbryt", role: .cancel) { pendingImport = nil; importPreview = nil }
        } message: {
            if let importPreview {
                Text("Nya titlar: \(importPreview.newLibraryItems). Matchande titlar lämnas orörda: \(importPreview.updatedLibraryItems). Lokala titlar som bara finns på den här enheten bevaras: \(importPreview.existingLibraryItems). Nya avsnittstillstånd: \(importPreview.newEpisodeStates). Seriehändelser: \(importPreview.newHistoryEvents). Filmhändelser: \(importPreview.newMovieHistoryEvents). Egna listor: \(importPreview.newCustomLists). Listposter: \(importPreview.newCustomListItems). Påminnelser: \(importPreview.newReminders).")
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

    private func handleImportSelection(_ result: Result<[URL], Error>) {
        do {
            let urls = try result.get()
            guard let url = urls.first else { return }
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
            let backup = try WatchlistBackupService.decode(Data(contentsOf: url))
            let preview = try WatchlistImportService.preview(backup, in: modelContext)
            pendingImport = backup
            importPreview = preview
            isConfirmingImport = true
        } catch { errorMessage = error.localizedDescription }
    }

    private func performImport() {
        guard let pendingImport else { return }
        do {
            let reminderIDs = Set(pendingImport.premiereReminders.map(\.stableID))
            let summary = try WatchlistImportService.merge(pendingImport, into: modelContext)
            self.pendingImport = nil
            importPreview = nil
            importedSummary = "Import klar. \(summary.newLibraryItems) nya titlar och \(summary.newHistoryEvents + summary.newMovieHistoryEvents) historikhändelser har lagts till. Befintliga poster behölls."
            restoreImportedNotifications(withIDs: reminderIDs)
        } catch { errorMessage = error.localizedDescription }
    }

    private func restoreImportedNotifications(withIDs stableIDs: Set<String>) {
        guard !stableIDs.isEmpty else { return }
        do {
            let reminders = try modelContext.fetch(FetchDescriptor<PremiereReminder>())
                .filter { stableIDs.contains($0.stableID) }
            Task {
                var scheduledCount = 0
                for reminder in reminders {
                    do {
                        if try await PremiereNotificationService.scheduleIfAuthorized(reminder) {
                            scheduledCount += 1
                        }
                    } catch {
                        // Keep the imported reminder record even if its date cannot be scheduled.
                    }
                }
                if scheduledCount > 0 {
                    importedSummary = (importedSummary ?? "Import klar.") + " \(scheduledCount) notiser schemalagda."
                }
            }
        } catch {
            errorMessage = "Importen sparades, men påminnelserna kunde inte läsas in."
        }
    }
}
