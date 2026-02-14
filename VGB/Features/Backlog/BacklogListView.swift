import SwiftUI
import SwiftData

// MARK: - Sort Mode

enum SortMode: String, CaseIterable, Identifiable {
    case priority    = "Priority"
    case metacritic  = "Metacritic"
    case openCritic  = "OpenCritic"
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

    /// Games after applying filters and sort.
    private var displayedGames: [Game] {
        var result = games

        if let status = filterStatus {
            result = result.filter { $0.status == status }
        }
        if let platform = filterPlatform {
            result = result.filter { $0.platform == platform }
        }
        if let genre = filterGenre {
            result = result.filter { $0.genre == genre }
        }

        switch sortMode {
        case .priority:
            // Already sorted by priorityPosition from @Query
            break
        case .metacritic:
            result.sort { ($0.metacriticScore ?? -1) > ($1.metacriticScore ?? -1) }
        case .openCritic:
            result.sort { ($0.openCriticScore ?? -1) > ($1.openCriticScore ?? -1) }
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

    // MARK: - No Results (filters active but nothing matches)

    private var noResultsState: some View {
        ContentUnavailableView {
            Label("No Matches", systemImage: "line.3.horizontal.decrease.circle")
        } description: {
            Text("No games match the current filters.")
        } actions: {
            Button("Clear Filters") { clearFilters() }
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
            ForEach(displayedGames) { game in
                NavigationLink(value: game) {
                    GameRowView(game: game)
                }
            }
            .onMove { source, destination in
                if sortMode == .priority {
                    reorder(from: source, to: destination)
                }
            }
            .onDelete(perform: delete)
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
        VStack(alignment: .leading, spacing: 4) {
            Text(game.title)
                .font(.headline)

            HStack(spacing: 12) {
                if !game.platform.isEmpty {
                    Label(game.platform, systemImage: "desktopcomputer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                StatusBadge(status: game.status)
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
        case .backlog:   .gray
        case .playing:   .blue
        case .completed: .green
        case .dropped:   .orange
        }
    }
}

#Preview {
    BacklogListView()
        .modelContainer(for: Game.self, inMemory: true)
}
