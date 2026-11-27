import SwiftUI

struct PersonalReviewSection: View {
    let rating: Int?
    let notes: String
    let onRatingChange: (Int?) -> Void
    let onNotesSave: (String) -> Void

    @State private var draftNotes = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("MINA OMDÖMEN")
                .font(.system(size: 9, weight: .bold))
                .tracking(1.7)
                .foregroundStyle(WatchlistColor.accent)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Mitt betyg")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(WatchlistColor.primaryText)
                    Spacer()
                    if let rating {
                        Text("\(rating)/10")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(WatchlistColor.accent)
                    } else {
                        Text("Inte betygsatt")
                            .font(.system(size: 11))
                            .foregroundStyle(WatchlistColor.mutedText)
                    }
                }

                HStack(spacing: 0) {
                    ForEach(1...10, id: \.self) { value in
                        Button {
                            onRatingChange(rating == value ? nil : value)
                        } label: {
                            Text("\(value)")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(rating == value ? WatchlistColor.background : WatchlistColor.secondaryText)
                                .frame(maxWidth: .infinity)
                                .frame(height: 34)
                                .background(rating == value ? WatchlistColor.accent : WatchlistColor.surfaceElevated, in: RoundedRectangle(cornerRadius: 7))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Betyg \(value) av 10")
                        .accessibilityHint(rating == value ? "Tryck igen för att ta bort betyget" : "Sätt ditt personliga betyg")
                        .accessibilityAddTraits(rating == value ? .isSelected : [])
                    }
                }
            }
            .padding(14)
            .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 13))

            VStack(alignment: .leading, spacing: 9) {
                Text("Mina anteckningar")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(WatchlistColor.primaryText)

                TextEditor(text: $draftNotes)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 12))
                    .foregroundStyle(WatchlistColor.primaryText)
                    .frame(minHeight: 92)
                    .padding(8)
                    .background(WatchlistColor.surfaceElevated, in: RoundedRectangle(cornerRadius: 9))

                HStack {
                    Spacer()
                    Button("Spara anteckning") {
                        onNotesSave(draftNotes.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WatchlistColor.accent)
                }
            }
            .padding(14)
            .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 13))
        }
        .onAppear { draftNotes = notes }
        .onChange(of: notes) { _, newValue in draftNotes = newValue }
    }
}
