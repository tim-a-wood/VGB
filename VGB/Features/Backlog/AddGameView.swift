import SwiftUI
import SwiftData

struct AddGameView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Search state

    @State private var searchText = ""
    @State private var searchResults: [IGDBGame] = []
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var searchTask: Task<Void, Never>?

    // MARK: - Selected game (from IGDB) or manual entry

    @State private var selectedIGDBGame: IGDBGame?

    // MARK: - Form fields

    @State private var title = ""
    @State private var platform = ""
    @State private var status: GameStatus = .backlog
    @State private var estimatedHours: Double?
    @State private var personalNotes = ""
    @State private var personalRating: Int?

    /// Current count of games so we can assign the next priority position.
    var existingGameCount: Int

    /// Whether the user has picked from IGDB results.
    private var hasIGDBSelection: Bool { selectedIGDBGame != nil }

    /// Whether the selected game is unreleased.
    private var isUnreleasedGame: Bool {
        guard let date = selectedIGDBGame?.releaseDate else { return false }
        return date > Date()
    }

    /// Statuses available for selection — unreleased games can only be Wishlist.
    private var availableStatuses: [GameStatus] {
        isUnreleasedGame ? [.wishlist] : Array(GameStatus.allCases)
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Search Section

                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search games…", text: $searchText)
                            .autocorrectionDisabled()
                            .onSubmit { triggerSearch() }
                            .accessibilityLabel("Search games on IGDB")
                            .accessibilityHint("Type to find games and prefill details")
                        if isSearching {
                            ProgressView()
                        }
                        if !searchText.isEmpty {
                            Button {
                                clearSearch()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Search IGDB")
                } footer: {
                    if isSearching {
                        Text("Searching…")
                            .foregroundStyle(.secondary)
                    } else if let error = searchError {
                        Text(error)
                            .foregroundStyle(.red)
                    } else if hasIGDBSelection {
                        Text("Prefilled from IGDB. You can still edit fields below.")
                    }
                }

                // MARK: - Search Results

                if !searchResults.isEmpty && !hasIGDBSelection {
                    Section("Results") {
                        ForEach(searchResults, id: \.id) { igdbGame in
                            Button {
                                selectGame(igdbGame)
                            } label: {
                                SearchResultRow(game: igdbGame)
                            }
                            .tint(.primary)
                        }
                    }
                }

                // MARK: - Game Info

                Section("Game Info") {
                    TextField("Title", text: $title)
                    TextField("Platform (e.g. PS5, PC, Switch)", text: $platform)

                    if let genre = selectedIGDBGame?.primaryGenre {
                        LabeledContent("Genre", value: genre)
                    }
                    if let dev = selectedIGDBGame?.developerName {
                        LabeledContent("Developer", value: dev)
                    }
                    if let date = selectedIGDBGame?.releaseDate {
                        LabeledContent("Release Date", value: date, format: .dateTime.year().month().day())
                    }
                    if let rating = selectedIGDBGame?.totalRating {
                        LabeledContent("Critic Score", value: "\(Int(rating))")
                    }
                }

                // MARK: - Status

                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(availableStatuses) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                }

                // MARK: - Your Details

                Section("Your Details") {
                    HStack {
                        Text("Estimated Hours")
                        Spacer()
                        TextField("Hours", value: $estimatedHours, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    .onChange(of: estimatedHours) { _, newValue in
                        if let v = newValue, v < 0 {
                            estimatedHours = 0
                        }
                    }

                    if !isUnreleasedGame {
                        HStack {
                            Text("Your Rating")
                            Spacer()
                            TextField("0–100", value: $personalRating, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                        .onChange(of: personalRating) { _, newValue in
                            if let v = newValue, (v < 0 || v > 100) {
                                personalRating = min(100, max(0, v))
                            }
                        }
                    }

                    TextField("Notes", text: $personalNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityLabel("Cancel adding game")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityLabel("Add game")
                        .accessibilityHint(title.trimmingCharacters(in: .whitespaces).isEmpty ? "Enter a title first" : "Saves the game to your catalog")
                }
            }
            .onChange(of: searchText) {
                // Debounced search: wait 500ms after typing stops
                searchTask?.cancel()
                guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
                    searchResults = []
                    searchError = nil
                    return
                }
                searchTask = Task {
                    try? await Task.sleep(for: .milliseconds(500))
                    guard !Task.isCancelled else { return }
                    await performSearch()
                }
            }
        }
    }

    // MARK: - Search

    private func triggerSearch() {
        searchTask?.cancel()
        searchTask = Task { await performSearch() }
    }

    private func performSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }

        isSearching = true
        searchError = nil

        do {
            let results = try await IGDBClient.shared.searchGames(query)
            // Only update if we're still on the same query
            if searchText.trimmingCharacters(in: .whitespaces) == query {
                searchResults = results
                if results.isEmpty {
                    searchError = "No games found for \"\(query)\"."
                }
            }
        } catch {
            searchError = error.localizedDescription
            searchResults = []
        }

        isSearching = false
    }

    private func selectGame(_ igdbGame: IGDBGame) {
        selectedIGDBGame = igdbGame
        searchResults = []

        // Prefill form fields from IGDB data
        title = igdbGame.name ?? ""
        platform = igdbGame.platformNames.joined(separator: ", ")

        // Auto-set status to Wishlist for unreleased games
        if let date = igdbGame.releaseDate, date > Date() {
            status = .wishlist
        }
    }

    private func clearSearch() {
        searchText = ""
        searchResults = []
        searchError = nil
        selectedIGDBGame = nil
    }

    // MARK: - Save

    private func save() {
        let game = Game(
            title: title.trimmingCharacters(in: .whitespaces),
            platform: platform.trimmingCharacters(in: .whitespaces),
            status: status,
            priorityPosition: existingGameCount
        )
        game.estimatedHours = estimatedHours.map { max(0, $0) }
        game.personalNotes = personalNotes
        game.personalRating = personalRating.map { min(100, max(0, $0)) }

        // Apply IGDB metadata if selected
        if let igdb = selectedIGDBGame {
            game.externalId = String(igdb.id)
            game.coverImageURL = igdb.coverURL
            game.genre = igdb.primaryGenre
            game.developer = igdb.developerName
            game.releaseDate = igdb.releaseDate
            game.igdbRating = igdb.totalRating.map { Int($0) }
            game.lastSyncedAt = Date()
        }

        modelContext.insert(game)
        Haptic.success.play()
        dismiss()
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    let game: IGDBGame

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let url = game.thumbnailURL, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.quaternary)
                        .overlay {
                            Image(systemName: "gamecontroller")
                                .foregroundStyle(.tertiary)
                        }
                }
                .frame(width: 45, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(game.name ?? "Unknown")
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let platforms = game.platforms, !platforms.isEmpty {
                        Text(platforms.compactMap(\.name).joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 8) {
                    if let date = game.releaseDate {
                        Text(date, format: .dateTime.year())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let rating = game.totalRating {
                        Label("\(Int(rating))", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            Image(systemName: "plus.circle")
                .foregroundStyle(.tint)
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    AddGameView(existingGameCount: 0)
        .modelContainer(for: Game.self, inMemory: true)
}
