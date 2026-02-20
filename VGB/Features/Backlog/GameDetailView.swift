import SwiftUI
import SwiftData

struct GameDetailView: View {
    @Bindable var game: Game
    @Environment(\.modelContext) private var modelContext

    @State private var isRefreshing = false
    @State private var refreshFailed = false
    @State private var showCelebration = false

    /// Whether this game is linked to IGDB (has an externalId).
    private var isLinked: Bool { game.externalId != nil }

    /// Statuses available for selection — unreleased games can only be Wishlist.
    private var availableStatuses: [GameStatus] {
        GameStatus.availableStatuses(for: game.isUnreleased)
    }

    /// Completed games without rating or estimated hours: show a subtle nudge to add them.
    private var completedWithoutRatingOrPlayTime: Bool {
        game.status == .completed && (game.personalRating == nil || game.estimatedHours == nil)
    }

    var body: some View {
        Form {
            coverSection
            statusSection
            if completedWithoutRatingOrPlayTime {
                completedPromptSection
            }
            gameInfoSection
            yourDetailsSection
            metadataSection
            actionsSection
        }
        .overlay {
            if showCelebration {
                CelebrationOverlay()
                    .allowsHitTesting(false)
            }
        }
        .navigationTitle(game.title)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: game.statusRaw) { oldValue, newValue in
            game.updatedAt = Date()
            if newValue == GameStatus.completed.rawValue && oldValue != newValue {
                Haptic.success.play()
                withAnimation {
                    showCelebration = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        showCelebration = false
                    }
                }
            }
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

    @ViewBuilder private var coverSection: some View {
        if let urlString = game.coverImageURL, let url = URL(string: urlString) {
            Section {
                HStack {
                    Spacer()
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.quaternary)
                            .aspectRatio(3/4, contentMode: .fit)
                            .overlay { ProgressView() }
                    }
                    .frame(maxHeight: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            }
        }
    }

    private var statusSection: some View {
        Section("Status") {
            Picker("Status", selection: $game.statusRaw) {
                ForEach(availableStatuses, id: \.rawValue) { s in
                    Text(s.rawValue).tag(s.rawValue)
                }
            }
        }
    }

    /// Subtle nudge to add rating or estimated hours when a completed game is missing them.
    private var completedPromptSection: some View {
        Section {
            Label {
                Text("Add a rating or estimated hours below to get more from Stats and Rankings.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "lightbulb")
                    .font(.system(size: 14))
                    .foregroundStyle(.orange.opacity(0.9))
            }
            .listRowBackground(Color.orange.opacity(0.06))
        }
    }

    @ViewBuilder private var gameInfoSection: some View {
        Section("Game Info") {
            LabeledContent("Title", value: game.title)
            if !game.platform.isEmpty {
                LabeledContent("Platform", value: game.displayPlatform)
            }
            if let date = game.releaseDate {
                HStack {
                    Text("Release Date")
                    Spacer()
                    Text(date, format: .dateTime.year().month().day())
                        .foregroundStyle(.secondary)
                    if game.isUnreleased {
                        Text("Unreleased")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.indigo.opacity(0.15))
                            .foregroundStyle(.indigo)
                            .clipShape(Capsule())
                    }
                }
            }
            if let genre = game.genre, !genre.isEmpty {
                LabeledContent("Genre", value: genre)
            }
            if let dev = game.developer, !dev.isEmpty {
                LabeledContent("Developer", value: dev)
            }
            if let rating = game.igdbRating {
                LabeledContent("Critic Score", value: "\(rating)")
            }
            if !game.isUnreleased {
                HStack {
                    Text("Your Rating")
                    Spacer()
                    TextField("0–100", value: $game.personalRating, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                .onChange(of: game.personalRating) { _, newValue in
                    if let v = newValue, (v < 0 || v > 100) {
                        game.personalRating = min(100, max(0, v))
                    }
                }
            }
        }
    }

    private var yourDetailsSection: some View {
        Section("Your Details") {
            HStack {
                Text("Estimated Hours")
                Spacer()
                TextField("Hours", value: $game.estimatedHours, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
            .onChange(of: game.estimatedHours) { _, newValue in
                if let v = newValue, v < 0 { game.estimatedHours = 0 }
            }
            TextField("Notes", text: $game.personalNotes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    @ViewBuilder private var metadataSection: some View {
        Section {
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
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                    } else {
                        Label("Never synced", systemImage: "exclamationmark.triangle")
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundStyle(.orange)
                    }
                } else {
                    Label("Added manually", systemImage: "pencil")
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isLinked {
                    Button {
                        Task { await refreshGame() }
                    } label: {
                        if isRefreshing { ProgressView() } else { Image(systemName: "arrow.clockwise") }
                    }
                    .disabled(isRefreshing)
                    .accessibilityLabel(isRefreshing ? "Refreshing metadata" : "Refresh metadata from IGDB")
                }
            }
            if refreshFailed {
                Text("Refresh failed. Your local data is unchanged.")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.red)
                    .accessibilityLabel("Refresh failed. Your local data is unchanged.")
            }
            LabeledContent("Added", value: game.createdAt, format: .dateTime.year().month().day())
        } header: {
            Text("Metadata")
        }
    }

    private var actionsSection: some View {
        Section {
            ShareLink(item: shareText) {
                Label("Share Game", systemImage: "square.and.arrow.up")
            }
            .accessibilityLabel("Share game")
            Button("Delete Game", role: .destructive) {
                Haptic.warning.play()
                modelContext.delete(game)
            }
            .accessibilityLabel("Delete game")
            .accessibilityHint("Removes this game from your catalog")
        }
    }

    // MARK: - Share

    private var shareText: String {
        var text = game.title
        if !game.platform.isEmpty {
            text += " (\(game.displayPlatform))"
        }
        text += " — \(game.status.rawValue)"
        if let rating = game.personalRating {
            text += " | My rating: \(rating)/100"
        }
        if let critic = game.igdbRating {
            text += " | Critic score: \(critic)"
        }
        text += "\n\nTracked with VGB"
        return text
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
            g.coverImageURL = "https://images.igdb.com/igdb/image/upload/t_cover_big/co4jni.jpg"
            g.lastSyncedAt = Date().addingTimeInterval(-8 * 24 * 60 * 60)
            return g
        }())
    }
    .modelContainer(for: Game.self, inMemory: true)
}
