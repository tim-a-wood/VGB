import SwiftUI
import SwiftData

struct BacklogListView: View {
    @Query(sort: \Game.priorityPosition) private var games: [Game]
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddGame = false

    var body: some View {
        NavigationStack {
            Group {
                if games.isEmpty {
                    emptyState
                } else {
                    gameList
                }
            }
            .navigationTitle("Backlog")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddGame = true
                    } label: {
                        Image(systemName: "plus")
                    }
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

    // MARK: - Game List

    private var gameList: some View {
        List {
            ForEach(games) { game in
                NavigationLink(value: game) {
                    GameRowView(game: game)
                }
            }
            .onMove(perform: reorder)
            .onDelete(perform: delete)
        }
        .navigationDestination(for: Game.self) { game in
            GameDetailView(game: game)
        }
    }

    // MARK: - Delete

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(games[index])
        }
    }

    // MARK: - Reorder

    private func reorder(from source: IndexSet, to destination: Int) {
        var ordered = games
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
