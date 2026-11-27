import SwiftUI
import SwiftData

struct CustomListsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomList.updatedAt, order: .reverse) private var lists: [CustomList]
    @Query private var memberships: [CustomListItem]
    @State private var showingCreate = false
    @State private var newListName = ""
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            WatchlistColor.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .lastTextBaseline) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("DIN KURERING")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1.8)
                                .foregroundStyle(WatchlistColor.accent)
                            Text("Mina listor")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(WatchlistColor.primaryText)
                        }
                        Spacer()
                        Button {
                            showingCreate = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(WatchlistColor.background)
                                .frame(width: 38, height: 38)
                                .background(WatchlistColor.accent, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Skapa ny lista")
                    }
                    .padding(.horizontal, 20)

                    if lists.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "rectangle.stack")
                                .font(.system(size: 34, weight: .light))
                                .foregroundStyle(WatchlistColor.accent)
                            Text("Skapa din första lista")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(WatchlistColor.primaryText)
                            Text("Samla filmer och serier efter tema, humör eller vem du vill se dem med.")
                                .font(.system(size: 12))
                                .foregroundStyle(WatchlistColor.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 35)
                        .padding(.vertical, 70)
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(lists) { list in
                                NavigationLink {
                                    CustomListDetailView(list: list)
                                } label: {
                                    listRow(list)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        delete(list)
                                    } label: {
                                        Label("Ta bort lista", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                    }
                }
                .padding(.top, 18)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCreate) {
            NavigationStack {
                ZStack {
                    WatchlistColor.background.ignoresSafeArea()
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Vad ska listan heta?")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(WatchlistColor.primaryText)
                        TextField("Exempelvis Kvällens thrillers", text: $newListName)
                            .textFieldStyle(.roundedBorder)
                        Spacer()
                    }
                    .padding(22)
                }
                .navigationTitle("Ny lista")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Avbryt") { showingCreate = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Skapa") { createList() }
                            .disabled(newListName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .alert("Kunde inte spara", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Ett oväntat fel uppstod.")
        }
    }

    private func listRow(_ list: CustomList) -> some View {
        let count = memberships.filter { $0.listID == list.id }.count
        let previews = memberships.filter { $0.listID == list.id }.sorted { $0.dateAdded < $1.dateAdded }.prefix(3)
        return HStack(spacing: 13) {
            HStack(spacing: -15) {
                ForEach(Array(previews)) { entry in
                    Group {
                        if let url = entry.mediaItem.posterURL {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image.resizable().scaledToFill()
                                } else {
                                    previewPlaceholder(entry)
                                }
                            }
                        } else {
                            previewPlaceholder(entry)
                        }
                    }
                    .frame(width: 42, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).stroke(WatchlistColor.background, lineWidth: 2))
                }
                if previews.isEmpty {
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(WatchlistColor.accent)
                        .frame(width: 48, height: 60)
                        .background(WatchlistColor.surfaceElevated, in: RoundedRectangle(cornerRadius: 9))
                }
            }
            .frame(width: 82, alignment: .leading)
            VStack(alignment: .leading, spacing: 5) {
                Text(list.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(WatchlistColor.primaryText)
                    .lineLimit(2)
                Text("\(count) TITLAR")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(WatchlistColor.secondaryText)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(WatchlistColor.mutedText)
        }
        .padding(13)
        .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private func previewPlaceholder(_ entry: CustomListItem) -> some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(WatchlistColor.surfaceElevated)
            .overlay {
                Image(systemName: entry.mediaKind == "movie" ? "film" : "tv")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(WatchlistColor.mutedText)
            }
    }

    private func createList() {
        let name = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        let list = CustomList(name: name)
        modelContext.insert(list)
        guard save() else {
            modelContext.delete(list)
            return
        }
        newListName = ""
        showingCreate = false
    }

    private func delete(_ list: CustomList) {
        for membership in memberships where membership.listID == list.id {
            modelContext.delete(membership)
        }
        modelContext.delete(list)
        save()
    }

    @discardableResult
    private func save() -> Bool {
        do {
            try modelContext.save()
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

private struct CustomListDetailView: View {
    let list: CustomList
    @Environment(\.modelContext) private var modelContext
    @Query private var allMemberships: [CustomListItem]
    @State private var errorMessage: String?
    @State private var showingRename = false
    @State private var renamedListName = ""

    private var entries: [CustomListItem] {
        allMemberships.filter { $0.listID == list.id }.sorted { $0.dateAdded > $1.dateAdded }
    }

    var body: some View {
        ZStack {
            WatchlistColor.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(list.name)
                            .font(.system(size: 27, weight: .bold, design: .rounded))
                            .foregroundStyle(WatchlistColor.primaryText)
                        Text("\(entries.count) filmer och serier")
                            .font(.system(size: 11))
                            .foregroundStyle(WatchlistColor.secondaryText)
                    }
                    .padding(.horizontal, 20)

                    if entries.isEmpty {
                        Text("Listan är tom. Lägg till titlar från deras detaljsidor.")
                            .font(.system(size: 12))
                            .foregroundStyle(WatchlistColor.secondaryText)
                            .padding(22)
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(entries) { entry in
                                NavigationLink(value: entry.mediaItem) {
                                    HStack(spacing: 12) {
                                        listPoster(entry)
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(entry.title)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundStyle(WatchlistColor.primaryText)
                                            Text(entry.mediaKind == "movie" ? "FILM" : "SERIE")
                                                .font(.system(size: 8, weight: .bold))
                                                .tracking(1)
                                                .foregroundStyle(WatchlistColor.mutedText)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 10))
                                            .foregroundStyle(WatchlistColor.mutedText)
                                    }
                                    .padding(10)
                                    .background(WatchlistColor.surface, in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        modelContext.delete(entry)
                                        list.updatedAt = .now
                                        save()
                                    } label: {
                                        Label("Ta bort från listan", systemImage: "minus.circle")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                    }
                }
                .padding(.top, 18)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    renamedListName = list.name
                    showingRename = true
                } label: {
                    Image(systemName: "pencil").foregroundStyle(WatchlistColor.accent)
                }
                .accessibilityLabel("Byt listans namn")
            }
        }
        .sheet(isPresented: $showingRename) {
            NavigationStack {
                ZStack {
                    WatchlistColor.background.ignoresSafeArea()
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Ge listan ett nytt namn")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(WatchlistColor.primaryText)
                        TextField("Listans namn", text: $renamedListName)
                            .textFieldStyle(.roundedBorder)
                        Spacer()
                    }
                    .padding(22)
                }
                .navigationTitle("Byt namn")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Avbryt") { showingRename = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Spara") { renameList() }
                            .disabled(renamedListName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .navigationDestination(for: MediaItem.self) { item in
            MediaDetailView(item: item)
        }
        .alert("Kunde inte spara", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Ett oväntat fel uppstod.")
        }
    }

    @ViewBuilder
    private func listPoster(_ entry: CustomListItem) -> some View {
        if let url = entry.mediaItem.posterURL {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    posterPlaceholder(entry)
                }
            }
            .frame(width: 48, height: 68)
            .clipShape(RoundedRectangle(cornerRadius: 7))
        } else {
            posterPlaceholder(entry)
        }
    }

    private func posterPlaceholder(_ entry: CustomListItem) -> some View {
        RoundedRectangle(cornerRadius: 7)
            .fill(WatchlistColor.surfaceElevated)
            .overlay {
                Image(systemName: entry.mediaKind == "movie" ? "film" : "tv")
                    .foregroundStyle(WatchlistColor.mutedText)
            }
            .frame(width: 48, height: 68)
    }

    private func renameList() {
        let newName = renamedListName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newName.isEmpty else { return }
        let previousName = list.name
        list.name = newName
        list.updatedAt = .now
        do {
            try modelContext.save()
            errorMessage = nil
            showingRename = false
        } catch {
            list.name = previousName
            do {
                try modelContext.save()
            } catch {
                errorMessage = "Listans namn kunde inte återställas: \\(error.localizedDescription)"
                return
            }
            errorMessage = error.localizedDescription
        }
    }

    private func save() {
        do {
            try modelContext.save()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
