import SwiftUI
import SwiftData

struct AddGameView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var platform = ""
    @State private var status: GameStatus = .backlog
    @State private var estimatedHours: Double?
    @State private var personalNotes = ""
    @State private var personalRating: Int?

    /// Current count of games so we can assign the next priority position.
    var existingGameCount: Int

    var body: some View {
        NavigationStack {
            Form {
                Section("Game Info") {
                    TextField("Title", text: $title)
                    TextField("Platform (e.g. PS5, PC, Switch)", text: $platform)
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(GameStatus.allCases) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Your Details") {
                    HStack {
                        Text("Estimated Hours")
                        Spacer()
                        TextField("Hours", value: $estimatedHours, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    HStack {
                        Text("Your Rating")
                        Spacer()
                        TextField("0–100", value: $personalRating, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
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
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    // MARK: - Save

    private func save() {
        let game = Game(
            title: title.trimmingCharacters(in: .whitespaces),
            platform: platform.trimmingCharacters(in: .whitespaces),
            status: status,
            priorityPosition: existingGameCount
        )
        game.estimatedHours = estimatedHours
        game.personalNotes = personalNotes
        game.personalRating = personalRating

        modelContext.insert(game)
        dismiss()
    }
}

#Preview {
    AddGameView(existingGameCount: 0)
        .modelContainer(for: Game.self, inMemory: true)
}
