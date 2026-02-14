import SwiftUI
import SwiftData

// MARK: - Sort Mode

enum SortMode: String, CaseIterable, Identifiable {
    case priority    = "Priority"
    case criticScore = "Critic Score"
    case releaseDate = "Release Date"

    var id: String { rawValue }
}

// MARK: - Backlog List

struct BacklogListView: View {
    @Query(sort: \Game.priorityPosition) private var games: [Game]
    @Environment(\.modelContext) private var modelContext

    @State private var showingAddGame = false
    @State private var sortMode: SortMode = .priority
    @State private var filterStatus: GameStatus?
    @State private var filterPlatform: String?
    @State private var filterGenre: String?
    @State private var searchText = ""
    @State private var showCelebration = false

    // MARK: - Derived data

    /// Unique platforms across all games (for filter menu).
    private var platforms: [String] {
        Array(Set(games.map(\.platform).filter { !$0.isEmpty })).sorted()
    }

    /// Unique genres across all games (for filter menu).
    private var genres: [String] {
        Array(Set(games.compactMap(\.genre).filter { !$0.isEmpty })).sorted()
    }

    /// Whether any filter is active.
    private var isFiltered: Bool {
        filterStatus != nil || filterPlatform != nil || filterGenre != nil
    }

    /// Games currently being played (for the pinned section).
    private var nowPlaying: [Game] {
        games.filter { $0.status == .playing }
    }

    /// Games after applying search, filters, and sort.
    private var displayedGames: [Game] {
        var result = games

        // Text search
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            result = result.filter { $0.title.lowercased().contains(query) }
        }

        // Status filter
        if let status = filterStatus {
            result = result.filter { $0.status == status }
        }

        // Platform filter
        if let platform = filterPlatform {
            result = result.filter { $0.platform == platform }
        }

        // Genre filter
        if let genre = filterGenre {
            result = result.filter { $0.genre == genre }
        }

        // Sort
        switch sortMode {
        case .priority:
            break // already sorted by priorityPosition from @Query
        case .criticScore:
            result.sort { ($0.igdbRating ?? -1) > ($1.igdbRating ?? -1) }
        case .releaseDate:
            result.sort { ($0.releaseDate ?? .distantPast) > ($1.releaseDate ?? .distantPast) }
        }

        return result
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if games.isEmpty {
                    emptyState
                } else if displayedGames.isEmpty {
                    noResultsState
                } else {
                    gameList
                }
            }
            .navigationTitle("Backlog")
            .searchable(text: $searchText, prompt: "Search games")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAddGame = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    filterMenu
                }
            }
            .sheet(isPresented: $showingAddGame) {
                AddGameView(existingGameCount: games.count)
            }
            .overlay {
                if showCelebration {
                    CelebrationOverlay()
                        .allowsHitTesting(false)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Games Yet", systemImage: "gamecontroller")
        } description: {
            Text("Add a game to start tracking your backlog.")
        }
    }

    // MARK: - No Results (filters/search active but nothing matches)

    private var noResultsState: some View {
        ContentUnavailableView {
            Label("No Matches", systemImage: "line.3.horizontal.decrease.circle")
        } description: {
            if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                Text("No games match \"\(searchText)\".")
            } else {
                Text("No games match the current filters.")
            }
        } actions: {
            if isFiltered || !searchText.isEmpty {
                Button("Clear Filters") {
                    clearFilters()
                    searchText = ""
                }
            }
        }
    }

    // MARK: - Filter / Sort Menu

    private var filterMenu: some View {
        Menu {
            // Sort
            Section("Sort By") {
                ForEach(SortMode.allCases) { mode in
                    Button {
                        sortMode = mode
                    } label: {
                        if sortMode == mode {
                            Label(mode.rawValue, systemImage: "checkmark")
                        } else {
                            Text(mode.rawValue)
                        }
                    }
                }
            }

            // Filter by status
            Section("Status") {
                Button {
                    filterStatus = nil
                } label: {
                    if filterStatus == nil {
                        Label("All", systemImage: "checkmark")
                    } else {
                        Text("All")
                    }
                }
                ForEach(GameStatus.allCases) { status in
                    Button {
                        filterStatus = status
                    } label: {
                        if filterStatus == status {
                            Label(status.rawValue, systemImage: "checkmark")
                        } else {
                            Text(status.rawValue)
                        }
                    }
                }
            }

            // Filter by platform
            if !platforms.isEmpty {
                Section("Platform") {
                    Button {
                        filterPlatform = nil
                    } label: {
                        if filterPlatform == nil {
                            Label("All", systemImage: "checkmark")
                        } else {
                            Text("All")
                        }
                    }
                    ForEach(platforms, id: \.self) { p in
                        Button {
                            filterPlatform = p
                        } label: {
                            if filterPlatform == p {
                                Label(p, systemImage: "checkmark")
                            } else {
                                Text(p)
                            }
                        }
                    }
                }
            }

            // Filter by genre
            if !genres.isEmpty {
                Section("Genre") {
                    Button {
                        filterGenre = nil
                    } label: {
                        if filterGenre == nil {
                            Label("All", systemImage: "checkmark")
                        } else {
                            Text("All")
                        }
                    }
                    ForEach(genres, id: \.self) { g in
                        Button {
                            filterGenre = g
                        } label: {
                            if filterGenre == g {
                                Label(g, systemImage: "checkmark")
                            } else {
                                Text(g)
                            }
                        }
                    }
                }
            }

            // Clear all
            if isFiltered {
                Section {
                    Button("Clear All Filters", role: .destructive) { clearFilters() }
                }
            }
        } label: {
            Image(systemName: isFiltered ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
    }

    // MARK: - Game List

    private var gameList: some View {
        List {
            // Pinned "Now Playing" section (only when not filtering by status and no search)
            if !nowPlaying.isEmpty && filterStatus == nil && searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                Section {
                    ForEach(nowPlaying) { game in
                        NavigationLink(value: game) {
                            GameRowView(game: game)
                        }
                        .swipeActions(edge: .trailing) {
                            swipeCompleted(game)
                            swipeDropped(game)
                        }
                    }
                } header: {
                    Label("Now Playing", systemImage: "play.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)
                }
            }

            // Main list
            Section {
                ForEach(displayedGames) { game in
                    NavigationLink(value: game) {
                        GameRowView(game: game)
                    }
                    .swipeActions(edge: .leading) {
                        if !game.isUnreleased {
                            swipePlayNow(game)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        if !game.isUnreleased {
                            swipeCompleted(game)
                            swipeDropped(game)
                        }
                    }
                }
                .onMove { source, destination in
                    if sortMode == .priority {
                        reorder(from: source, to: destination)
                    }
                }
                .onDelete(perform: delete)
            } header: {
                if !nowPlaying.isEmpty && filterStatus == nil && searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text("All Games")
                }
            }
        }
        .navigationDestination(for: Game.self) { game in
            GameDetailView(game: game)
        }
    }

    // MARK: - Actions

    private func clearFilters() {
        filterStatus = nil
        filterPlatform = nil
        filterGenre = nil
    }

    private func delete(at offsets: IndexSet) {
        let toDelete = offsets.map { displayedGames[$0] }
        for game in toDelete {
            modelContext.delete(game)
        }
    }

    // MARK: - Swipe Actions

    private func swipePlayNow(_ game: Game) -> some View {
        Button {
            game.status = .playing
            game.updatedAt = Date()
        } label: {
            Label("Playing", systemImage: "play.fill")
        }
        .tint(.blue)
    }

    private func swipeCompleted(_ game: Game) -> some View {
        Button {
            game.status = .completed
            game.updatedAt = Date()
            withAnimation {
                showCelebration = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    showCelebration = false
                }
            }
        } label: {
            Label("Completed", systemImage: "checkmark.circle.fill")
        }
        .tint(.green)
    }

    private func swipeDropped(_ game: Game) -> some View {
        Button {
            game.status = .dropped
            game.updatedAt = Date()
        } label: {
            Label("Drop", systemImage: "xmark.circle.fill")
        }
        .tint(.orange)
    }

    private func reorder(from source: IndexSet, to destination: Int) {
        var ordered = displayedGames
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, game) in ordered.enumerated() {
            game.priorityPosition = index
        }
    }
}

// MARK: - Row

private struct GameRowView: View {
    let game: Game

    var body: some View {
        HStack(spacing: 12) {
            // Cover art thumbnail
            if let urlString = game.coverImageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.quaternary)
                        .overlay {
                            Image(systemName: "gamecontroller")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                }
                .frame(width: 44, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.quaternary)
                    .frame(width: 44, height: 58)
                    .overlay {
                        Image(systemName: "gamecontroller")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(game.title)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if !game.platform.isEmpty {
                        Text(game.platform)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    if let rating = game.igdbRating {
                        Label("\(rating)", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                HStack(spacing: 6) {
                    StatusBadge(status: game.status)

                    if game.isUnreleased {
                        UnreleasedBadge()
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Status Badge

private struct StatusBadge: View {
    let status: GameStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var color: Color {
        switch status {
        case .wishlist:  .purple
        case .backlog:   .gray
        case .playing:   .blue
        case .completed: .green
        case .dropped:   .orange
        }
    }
}

// MARK: - Unreleased Badge

private struct UnreleasedBadge: View {
    var body: some View {
        Text("Unreleased")
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(.indigo.opacity(0.15))
            .foregroundStyle(.indigo)
            .clipShape(Capsule())
    }
}

#Preview {
    BacklogListView()
        .modelContainer(for: Game.self, inMemory: true)
}
