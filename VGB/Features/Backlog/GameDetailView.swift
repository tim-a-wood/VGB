import SwiftUI
import SwiftData

struct GameDetailView: View {
    @Bindable var game: Game
    @Environment(\.modelContext) private var modelContext

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
                if let mc = game.metacriticScore {
                    LabeledContent("Metacritic", value: "\(mc)")
                }

                if let oc = game.openCriticScore {
                    LabeledContent("OpenCritic", value: "\(oc)")
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

            // MARK: - Metadata

            Section("Metadata") {
                if let synced = game.lastSyncedAt {
                    LabeledContent("Last Synced", value: synced, format: .relative(presentation: .named))
                } else {
                    LabeledContent("Last Synced", value: "Never")
                }

                LabeledContent("Added", value: game.createdAt, format: .dateTime.year().month().day())
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
}

#Preview {
    NavigationStack {
        GameDetailView(game: {
            let g = Game(title: "Elden Ring", platform: "PS5", status: .playing)
            g.metacriticScore = 96
            g.openCriticScore = 95
            g.estimatedHours = 80
            g.personalRating = 92
            g.personalNotes = "Amazing open world"
            return g
        }())
    }
    .modelContainer(for: Game.self, inMemory: true)
}
