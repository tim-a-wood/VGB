import SwiftUI
import SwiftData
import WidgetKit

// MARK: - Backlog List View

struct BacklogListView: View {
    @Query(sort: \Game.priorityPosition) private var games: [Game]
    @Environment(\.modelContext) private var modelContext

    @State private var showingAddGame = false
    @State private var addGameInitialStatus: GameStatus?
    @State private var sortMode: SortMode = .priority
    @State private var filterStatus: GameStatus?
    @State private var filterPlatform: String?
    @State private var filterGenre: String?
    @State private var searchText = ""
    @State private var showCelebration = false
    @State private var showUnreleasedWarning = false
    @State private var collapsedSections: Set<GameStatus> = []
    @State private var isRefreshingAll = false
    @State private var gameToRate: Game?
    @State private var gameJustCompleted: Game?
    @State private var gameToPromptForDetails: Game?
    @State private var gameToOpenForDetails: Game?
    @State private var gamesReleasedFromWishlist: [Game] = []

    private var display: BacklogSectionedDisplay {
        BacklogCatalogLogic.sectionedDisplay(
            games: games,
            searchText: searchText,
            filterStatus: filterStatus,
            filterPlatform: filterPlatform,
            filterGenre: filterGenre,
            sortMode: sortMode
        )
    }

    private var platforms: [String] { BacklogCatalogLogic.platforms(from: games) }
    private var genres: [String] { BacklogCatalogLogic.genres(from: games) }
    private var statusCounts: [GameStatus: Int] { BacklogCatalogLogic.statusCounts(from: games) }
    private var isFiltered: Bool { filterStatus != nil || filterPlatform != nil || filterGenre != nil }
    private var showStatusSections: Bool {
        BacklogCatalogLogic.showStatusSections(filterStatus: filterStatus, searchText: searchText)
    }

    var body: some View {
        NavigationStack {
            Group {
                if games.isEmpty {
                    BacklogEmptyStateView()
                } else if display.displayed.isEmpty {
                    BacklogNoResultsStateView(
                        searchText: searchText,
                        isFiltered: isFiltered,
                        onClear: { clearFilters(); searchText = "" }
                    )
                } else {
                    VStack(spacing: 0) {
                        CatalogSummaryRowView(statusCounts: statusCounts) { status in
                        filterStatus = filterStatus == status ? nil : status
                    }
                        gameListContent
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search games")
            .alert("This game isn't released yet!", isPresented: $showUnreleasedWarning) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Unreleased games stay in Wishlist until they have a release date.")
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAddGame = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add game")
                }
                ToolbarItem(placement: .topBarLeading) {
                    BacklogFilterMenuView(
                        sortMode: $sortMode,
                        filterStatus: $filterStatus,
                        filterPlatform: $filterPlatform,
                        filterGenre: $filterGenre,
                        platforms: platforms,
                        genres: genres,
                        isFiltered: isFiltered,
                        onClearFilters: clearFilters
                    )
                    .accessibilityLabel("Filter and sort games")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    refreshButton
                }
            }
            .sheet(isPresented: $showingAddGame) {
                AddGameView(existingGameCount: games.count, initialStatus: addGameInitialStatus ?? .backlog)
            }
            .onChange(of: showingAddGame) { _, visible in
                if !visible { addGameInitialStatus = nil }
            }
            .overlay {
                if showCelebration {
                    CelebrationOverlay()
                        .allowsHitTesting(false)
                }
            }
            .sheet(item: $gameToRate) { game in
                RatingSheet(game: game) { gameToRate = nil }
            }
            .sheet(item: $gameToPromptForDetails) { game in
                BacklogAddDetailsPromptSheet(
                    game: game,
                    onAdd: {
                        gameToOpenForDetails = game
                        gameToPromptForDetails = nil
                    },
                    onLater: { gameToPromptForDetails = nil }
                )
            }
            .sheet(item: $gameToOpenForDetails, onDismiss: { gameToOpenForDetails = nil }) { game in
                NavigationStack {
                    GameDetailView(game: game)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { gameToOpenForDetails = nil }
                            }
                        }
                }
            }
            .confirmationDialog("Games Released", isPresented: Binding(
                get: { !gamesReleasedFromWishlist.isEmpty },
                set: { if !$0 { gamesReleasedFromWishlist = [] } }
            )) {
                Button("Move to Backlog") {
                    for game in gamesReleasedFromWishlist {
                        game.status = .backlog
                        game.updatedAt = Date()
                    }
                    gamesReleasedFromWishlist = []
                    pushWidgetSummaryFromContext()
                }
                Button("Keep in Wishlist", role: .cancel) {
                    gamesReleasedFromWishlist = []
                }
            } message: {
                let count = gamesReleasedFromWishlist.count
                let names = gamesReleasedFromWishlist.prefix(3).map(\.title).joined(separator: ", ")
                let suffix = count > 3 ? " and \(count - 3) more" : ""
                Text("\(count) game\(count == 1 ? "" : "s") in your wishlist \(count == 1 ? "has" : "have") been released: \(names)\(suffix). Move \(count == 1 ? "it" : "them") to Backlog?")
            }
        }
    }

    private var refreshButton: some View {
        let hasLinkedGames = games.contains { $0.externalId != nil }
        return Button {
            guard hasLinkedGames, !isRefreshingAll else { return }
            isRefreshingAll = true
            Task {
                let released = await GameSyncService.shared.refreshAllGames(in: modelContext)
                await MainActor.run {
                    isRefreshingAll = false
                    if !released.isEmpty { gamesReleasedFromWishlist = released }
                }
            }
        } label: {
            if isRefreshingAll {
                ProgressView().scaleEffect(0.85)
            } else {
                Image(systemName: "arrow.clockwise")
            }
        }
        .disabled(!hasLinkedGames || isRefreshingAll)
        .accessibilityLabel(isRefreshingAll ? "Refreshing metadata" : "Refresh metadata for all games")
    }

    private var gameListContent: some View {
        Group {
            if showStatusSections {
                sectionedListContent
            } else {
                List { singleSectionContent }
            }
        }
        .navigationDestination(for: Game.self) { game in
            GameDetailView(game: game)
        }
    }

    private var sectionedListContent: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                sectionBlockView(status: .playing, games: display.nowPlaying, onMoveToCompleted: nil)
                sectionBlockView(status: .backlog, games: display.backlog, onMoveToCompleted: nil)
                sectionBlockView(status: .wishlist, games: display.wishlist, onMoveToCompleted: nil)
                sectionBlockView(status: .completed, games: display.completed, onMoveToCompleted: onGameMovedToCompleted)
                sectionBlockView(status: .dropped, games: display.dropped, onMoveToCompleted: nil)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }

    private func sectionBlockView(
        status: GameStatus,
        games: [Game],
        onMoveToCompleted: ((Game) -> Void)?
    ) -> some View {
        BacklogSectionBlockView(
            status: status,
            games: games,
            isExpanded: !collapsedSections.contains(status),
            onToggle: {
                withAnimation(.easeInOut(duration: 0.25)) { collapsedSections.formSymmetricDifference([status]) }
            },
            onAddGame: {
                addGameInitialStatus = status
                showingAddGame = true
            },
            rowContent: { game, index in
                BacklogDraggableRowView(
                    game: game,
                    targetStatus: status,
                    sectionGames: games,
                    sectionIndex: index,
                    onMoveToCompleted: onMoveToCompleted,
                    rank: status == .completed && index < 3 ? index + 1 : nil,
                    isMostAnticipated: status == .wishlist && index == 0,
                    onHandleRowDrop: { id, st, gs, idx, onCompleted in
                        handleRowDrop(droppedId: id, targetStatus: st, sectionGames: gs, destinationIndex: idx, onMoveToCompleted: onCompleted, onUnreleasedWarning: { showUnreleasedWarning = true })
                    },
                    onRateTap: { gameToRate = game },
                    contextMenuContent: moveToContextMenuContent
                )
            }
        )
    }

    private var singleSectionContent: some View {
        Section {
            ForEach(Array(display.displayed.enumerated()), id: \.element.id) { index, game in
                singleSectionRow(for: game, priorityInGroup: index + 1) {
                    swipeCompleted(game)
                    swipeDropped(game)
                }
            }
            .onMove { source, destination in
                if sortMode == .priority { reorder(from: source, to: destination) }
            }
            .onDelete(perform: delete)
        } header: {
            if let status = filterStatus {
                let meta = status.sectionMetadata
                Label(meta.title, systemImage: meta.systemImage)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(meta.color)
            }
        }
    }

    private func singleSectionRow(for game: Game, priorityInGroup: Int? = nil, @ViewBuilder trailingSwipe: () -> some View) -> some View {
        NavigationLink(value: game) {
            BacklogGameRowView(game: game, onRateTap: { gameToRate = game }, priorityInGroup: priorityInGroup)
                .equatable()
        }
        .draggable(game.id.uuidString)
        .contextMenu { moveToContextMenuContent(for: game) }
        .swipeActions(edge: .leading) {
            if !game.isUnreleased { swipePlayNow(game) }
        }
        .swipeActions(edge: .trailing) {
            trailingSwipe()
        }
        .modifier(BacklogRowDropModifier(
            targetStatus: filterStatus,
            onMoveToCompleted: nil,
            modelContext: modelContext
        ))
    }

    @ViewBuilder
    private func moveToContextMenuContent(for game: Game) -> some View {
        ForEach(GameStatus.allCases, id: \.id) { status in
            if game.status != status {
                Button {
                    if game.isUnreleased && status != .wishlist {
                        showUnreleasedWarning = true
                    } else {
                        game.status = status
                        game.updatedAt = Date()
                        if status == .completed { onGameMovedToCompleted(game) }
                    }
                } label: {
                    Label("Move to \(status.rawValue)", systemImage: status.sectionIcon)
                }
            }
        }
    }

    // MARK: - Actions

    private func pushWidgetSummaryFromContext() {
        let descriptor = FetchDescriptor<Game>(sortBy: [SortDescriptor(\.priorityPosition)])
        guard let allGames = try? modelContext.fetch(descriptor) else { return }
        WidgetSummaryStorage.write(WidgetSummaryBuilder.make(from: allGames))
        WidgetCenter.shared.reloadTimelines(ofKind: "VGBWidget")
    }

    private func handleRowDrop(
        droppedId: UUID,
        targetStatus: GameStatus,
        sectionGames: [Game],
        destinationIndex: Int,
        onMoveToCompleted: ((Game) -> Void)?,
        onUnreleasedWarning: (() -> Void)? = nil
    ) {
        var descriptor = FetchDescriptor<Game>(predicate: #Predicate<Game> { $0.id == droppedId })
        descriptor.fetchLimit = 1
        guard let droppedGame = try? modelContext.fetch(descriptor).first else { return }
        let sameSection = droppedGame.status == targetStatus
        let reorderable: Set<GameStatus> = [.playing, .backlog, .wishlist, .completed, .dropped]
        if sameSection, reorderable.contains(targetStatus),
           let sourceIndex = sectionGames.firstIndex(where: { $0.id == droppedId }) {
            if sourceIndex == destinationIndex { return }
            let toOffset = sourceIndex < destinationIndex
                ? min(destinationIndex + 1, sectionGames.count)
                : destinationIndex
            reorderInSection(games: sectionGames, from: IndexSet(integer: sourceIndex), to: toOffset, targetStatus: targetStatus)
            Haptic.dropSnap.play()
        } else {
            applyDropToGame(droppedId, targetStatus: targetStatus, onMoveToCompleted: onMoveToCompleted, onUnreleasedWarning: onUnreleasedWarning)
            Haptic.dropSnap.play()
        }
    }

    private func applyDropToGame(
        _ gameId: UUID,
        targetStatus: GameStatus,
        onMoveToCompleted: ((Game) -> Void)?,
        onUnreleasedWarning: (() -> Void)? = nil
    ) {
        var descriptor = FetchDescriptor<Game>(predicate: #Predicate<Game> { $0.id == gameId })
        descriptor.fetchLimit = 1
        guard let game = try? modelContext.fetch(descriptor).first else { return }
        let effectiveStatus = game.isUnreleased ? GameStatus.wishlist : targetStatus
        if game.isUnreleased && targetStatus != .wishlist { onUnreleasedWarning?() }
        game.status = effectiveStatus
        game.updatedAt = Date()
        if effectiveStatus == .completed { onMoveToCompleted?(game) }
    }

    private func onGameMovedToCompleted(_ game: Game) {
        gameJustCompleted = game
        triggerCelebration()
    }

    private func triggerCelebration() {
        Haptic.success.play()
        withAnimation { showCelebration = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showCelebration = false }
            if let g = gameJustCompleted, g.personalRating == nil || g.estimatedHours == nil {
                gameToPromptForDetails = g
            }
            gameJustCompleted = nil
        }
    }

    private func reorderInSection(games: [Game], from source: IndexSet, to destination: Int, targetStatus: GameStatus) {
        var newOrder = games
        newOrder.move(fromOffsets: source, toOffset: destination)
        let d = display
        let reordered: [Game] = switch targetStatus {
        case .playing: newOrder + d.backlog + d.wishlist + d.completed + d.dropped
        case .backlog: d.nowPlaying + newOrder + d.wishlist + d.completed + d.dropped
        case .wishlist: d.nowPlaying + d.backlog + newOrder + d.completed + d.dropped
        case .completed: d.nowPlaying + d.backlog + d.wishlist + newOrder + d.dropped
        case .dropped: d.nowPlaying + d.backlog + d.wishlist + d.completed + newOrder
        }
        withAnimation(.easeOut(duration: 0.18)) {
            for (index, game) in reordered.enumerated() {
                game.priorityPosition = index
            }
        }
    }

    private func clearFilters() {
        filterStatus = nil
        filterPlatform = nil
        filterGenre = nil
    }

    private func delete(at offsets: IndexSet) {
        let toDelete = offsets.map { display.displayed[$0] }
        for game in toDelete {
            modelContext.delete(game)
        }
    }

    private func swipePlayNow(_ game: Game) -> some View {
        Button {
            game.status = .playing
            game.updatedAt = Date()
        } label: { Label("Playing", systemImage: "play.fill") }
        .tint(.blue)
    }

    private func swipeCompleted(_ game: Game) -> some View {
        Button {
            game.status = .completed
            game.updatedAt = Date()
            gameJustCompleted = game
            triggerCelebration()
        } label: { Label("Completed", systemImage: "checkmark.circle.fill") }
        .tint(.green)
    }

    private func swipeDropped(_ game: Game) -> some View {
        Button {
            game.status = .dropped
            game.updatedAt = Date()
        } label: { Label("Drop", systemImage: "xmark.circle.fill") }
        .tint(.orange)
    }

    private func reorder(from source: IndexSet, to destination: Int) {
        var ordered = display.displayed
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, game) in ordered.enumerated() {
            game.priorityPosition = index
        }
    }
}

// MARK: - Preview

#Preview {
    BacklogListView()
        .modelContainer(for: Game.self, inMemory: true)
}
