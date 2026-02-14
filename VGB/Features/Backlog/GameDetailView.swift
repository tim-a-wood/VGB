import SwiftUI
import SwiftData

struct GameDetailView: View {
    @Bindable var game: Game
    @Environment(\.modelContext) private var modelContext

    @State private var isRefreshing = false
    @State private var refreshFailed = false

    /// Whether this game is linked to IGDB (has an externalId).
    private var isLinked: Bool { game.externalId != nil }

    var body: some View {
        Form {
            // MARK: - Status

            Section("Status") {
                Picker("Status", selection: $game.statusRaw) {
                    ForEach(GameStatus.allCases) { s in
                        Text(s.rawValue).tag(s.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }

            // MARK: - Game Info

            Section("Game Info") {
                LabeledContent("Title", value: game.title)

                if !game.platform.isEmpty {
                    LabeledContent("Platform", value: game.platform)
                }

                if let date = game.releaseDate {
                    LabeledContent("Release Date", value: date, format: .dateTime.year().month().day())
                }

                if let genre = game.genre, !genre.isEmpty {
                    LabeledContent("Genre", value: genre)
                }

                if let dev = game.developer, !dev.isEmpty {
                    LabeledContent("Developer", value: dev)
                }
            }

            // MARK: - Scores

            Section("Scores") {
                if let rating = game.igdbRating {
                    LabeledContent("Critic Score", value: "\(rating)")
                }

                HStack {
                    Text("Your Rating")
                    Spacer()
                    TextField("0–100", value: $game.personalRating, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }

            // MARK: - Your Details

            Section("Your Details") {
                HStack {
                    Text("Estimated Hours")
                    Spacer()
                    TextField("Hours", value: $game.estimatedHours, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }

                TextField("Notes", text: $game.personalNotes, axis: .vertical)
                    .lineLimit(3...6)
            }

            // MARK: - Sync Info

            Section {
                // Stale indicator
                HStack {
                    if isLinked {
                        if let synced = game.lastSyncedAt {
                            let isStale = GameSyncService.shared.isStale(game)
                            Label {
                                Text("Synced \(synced, format: .relative(presentation: .named))")
                            } icon: {
                                Image(systemName: isStale ? "exclamationmark.arrow.circlepath" : "checkmark.circle")
                                    .foregroundStyle(isStale ? .orange : .green)
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        } else {
                            Label("Never synced", systemImage: "exclamationmark.triangle")
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                        }
                    } else {
                        Label("Added manually", systemImage: "pencil")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Manual refresh button
                    if isLinked {
                        Button {
                            Task { await refreshGame() }
                        } label: {
                            if isRefreshing {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                        .disabled(isRefreshing)
                    }
                }

                if refreshFailed {
                    Text("Refresh failed. Your local data is unchanged.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                LabeledContent("Added", value: game.createdAt, format: .dateTime.year().month().day())
            } header: {
                Text("Metadata")
            }

            // MARK: - Delete

            Section {
                Button("Delete Game", role: .destructive) {
                    modelContext.delete(game)
                }
            }
        }
        .navigationTitle(game.title)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: game.statusRaw) {
            game.updatedAt = Date()
        }
        .onChange(of: game.personalRating) {
            game.updatedAt = Date()
        }
        .onChange(of: game.estimatedHours) {
            game.updatedAt = Date()
        }
        .onChange(of: game.personalNotes) {
            game.updatedAt = Date()
        }
    }

    // MARK: - Refresh

    private func refreshGame() async {
        isRefreshing = true
        refreshFailed = false

        let success = await GameSyncService.shared.refreshGame(game)
        if !success {
            refreshFailed = true
        }

        isRefreshing = false
    }
}

#Preview {
    NavigationStack {
        GameDetailView(game: {
            let g = Game(title: "Elden Ring", platform: "PS5", status: .playing)
            g.igdbRating = 96
            g.estimatedHours = 80
            g.personalRating = 92
            g.personalNotes = "Amazing open world"
            g.externalId = "119133"
            g.lastSyncedAt = Date().addingTimeInterval(-8 * 24 * 60 * 60) // 8 days ago (stale)
            return g
        }())
    }
    .modelContainer(for: Game.self, inMemory: true)
}
