import SwiftUI

struct TMDBSettingsView: View {
    @State private var token = ""
    @State private var isConfigured = false
    @State private var feedback: String?
    @State private var feedbackIsError = false

    var body: some View {
        ZStack {
            WatchlistColor.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 9) {
                        Text("ANSLUT DIN FILMKATALOG")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.8)
                            .foregroundStyle(WatchlistColor.accent)
                        Text("TMDB")
                            .font(.system(size: 30, weight: .bold, design: .serif))
                            .foregroundStyle(WatchlistColor.primaryText)
                        Text("Anslut Watchlist till The Movie Database för att söka bland filmer och serier, visa affischer, läsa beskrivningar och hämta säsonger och avsnitt.")
                            .font(.system(size: 13))
                            .foregroundStyle(WatchlistColor.secondaryText)
                            .lineSpacing(4)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: isConfigured ? "checkmark.seal.fill" : "link")
                            .font(.system(size: 19))
                            .foregroundStyle(isConfigured ? WatchlistColor.accent : WatchlistColor.secondaryText)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(isConfigured ? "TMDB är anslutet" : "Ingen anslutning ännu")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(WatchlistColor.primaryText)
                            Text(isConfigured ? "Åtkomsttoken finns sparad på den här enheten." : "Lägg till en läsbehörig API-token för att aktivera katalogen.")
                                .font(.system(size: 10))
                                .foregroundStyle(WatchlistColor.secondaryText)
                        }
                        Spacer()
                    }
                    .padding(15)
                    .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("API-ÅTKOMSTTOKEN")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.2)
                            .foregroundStyle(WatchlistColor.mutedText)
                        SecureField("Klistra in din TMDB-token", text: $token)
                            .textContentType(.password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.system(size: 13))
                            .padding(14)
                            .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(WatchlistColor.hairline, lineWidth: 1))
                        Text("Token lagras i iOS-nyckelringen på enheten. Den bäddas inte in i appens kod eller skickas till Watchlists servrar.")
                            .font(.system(size: 10))
                            .foregroundStyle(WatchlistColor.mutedText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button(action: saveToken) {
                        Text("Spara och anslut")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(WatchlistColor.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(WatchlistColor.accent, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if isConfigured {
                        Button(role: .destructive, action: removeToken) {
                            Text("Koppla från TMDB")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    }

                    if let feedback {
                        Text(feedback)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(feedbackIsError ? Color.red : WatchlistColor.accent)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Så skaffar du en token")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(WatchlistColor.primaryText)
                        Text("Skapa ett kostnadsfritt konto hos TMDB och skapa en API Read Access Token under inställningarna för API. Det är den långa Bearer-tokenen som ska klistras in här – inte API-nyckeln.")
                            .font(.system(size: 11))
                            .foregroundStyle(WatchlistColor.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        Link("Öppna TMDB", destination: URL(string: "https://www.themoviedb.org/settings/api")!)
                            .font(.system(size: 12, weight: .semibold))
                            .tint(WatchlistColor.accent)
                    }
                    .padding(15)
                    .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(20)
            }
        }
        .navigationTitle("TMDB")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { isConfigured = TMDBConfiguration.isConfigured }
    }

    private func saveToken() {
        guard TMDBTokenStore.save(token) else {
            feedback = "Token kunde inte sparas. Kontrollera värdet och försök igen."
            feedbackIsError = true
            return
        }
        token = ""
        isConfigured = true
        feedback = "Token sparad säkert. Gå till Upptäck och prova en sökning."
        feedbackIsError = false
    }

    private func removeToken() {
        guard TMDBTokenStore.delete() else {
            feedback = "Token kunde inte tas bort."
            feedbackIsError = true
            return
        }
        isConfigured = false
        token = ""
        feedback = "TMDB är frånkopplat."
        feedbackIsError = false
    }
}
