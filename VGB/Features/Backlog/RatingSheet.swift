import SwiftUI
import SwiftData

/// Subtle sheet for providing or updating a game's personal rating (0–100).
struct RatingSheet: View {
    @Bindable var game: Game
    var onDismiss: () -> Void

    @State private var draftRating: Int

    init(game: Game, onDismiss: @escaping () -> Void) {
        self.game = game
        self.onDismiss = onDismiss
        _draftRating = State(initialValue: game.personalRating ?? 50)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(game.title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack(spacing: 16) {
                    Slider(value: Binding(
                        get: { Double(draftRating) },
                        set: { draftRating = Int($0.rounded()) }
                    ), in: 0...100, step: 1)
                    .tint(.blue)

                    Text("\(draftRating)")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.blue)
                        .frame(width: 36, alignment: .trailing)
                }
                .padding(.horizontal)

                HStack(spacing: 8) {
                    ForEach([50, 70, 85, 95], id: \.self) { preset in
                        Button {
                            Haptic.light.play()
                            draftRating = preset
                        } label: {
                            Text("\(preset)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(draftRating == preset ? .white : .primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(draftRating == preset ? Color.blue : Color(.tertiarySystemFill))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.top, 24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveAndDismiss()
                    }
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .bottomBar) {
                    if game.personalRating != nil {
                        Button("Clear rating", role: .destructive) {
                            game.personalRating = nil
                            game.updatedAt = Date()
                            Haptic.light.play()
                            onDismiss()
                        }
                    }
                }
            }
        }
        .presentationDetents([.height(260)])
        .presentationDragIndicator(.visible)
    }

    private func saveAndDismiss() {
        let clamped = min(100, max(0, draftRating))
        game.personalRating = clamped
        game.updatedAt = Date()
        Haptic.success.play()
        onDismiss()
    }
}

#Preview {
    RatingSheet(game: Game(title: "Elden Ring", platform: "PS5", status: .completed), onDismiss: {})
        .modelContainer(for: Game.self, inMemory: true)
}
