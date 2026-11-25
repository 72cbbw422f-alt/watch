import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BackupSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var document: WatchlistBackupDocument?
    @State private var isExporting = false
    @State private var errorMessage: String?
    @State private var exportedSummary: String?

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
                        Text("Skapa en JSON-fil med ditt bibliotek och din personliga tittarhistorik.")
                            .font(.system(size: 13))
                            .foregroundStyle(WatchlistColor.secondaryText)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        backupRow("Bibliotek", detail: "Status, favoriter, betyg och anteckningar")
                        backupRow("Avsnittsprogress", detail: "Vilka avsnitt som är markerade som sedda")
                        backupRow("Visningshistorik", detail: "Varje registrerat tittillfälle och omtittning")
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

                    if let exportedSummary {
                        Text(exportedSummary)
                            .font(.system(size: 11))
                            .foregroundStyle(WatchlistColor.secondaryText)
                    }

                    Text("Format: JSON · Schema v1. Exporten innehåller även metadata från TMDB som behövs för att återskapa dina poster. Ingen information skickas till en server.")
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
            case .success:
                exportedSummary = "Säkerhetskopian har exporterats."
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
        .alert("Kunde inte skapa säkerhetskopia", isPresented: Binding(
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
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(WatchlistColor.primaryText)
            Text(detail)
                .font(.system(size: 10))
                .foregroundStyle(WatchlistColor.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func prepareExport() {
        do {
            let backup = try WatchlistBackupService.makeBackup(from: modelContext)
            document = WatchlistBackupDocument(data: try WatchlistBackupService.encode(backup))
            exportedSummary = nil
            isExporting = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
