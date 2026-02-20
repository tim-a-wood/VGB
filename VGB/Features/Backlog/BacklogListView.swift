import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import WidgetKit

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
    @State private var addGameInitialStatus: GameStatus?
    @State private var sortMode: SortMode = .priority
    @State private var filterStatus: GameStatus?
    @State private var filterPlatform: String?
    @State private var filterGenre: String?
    @State private var searchText = ""
    @State private var showCelebration = false
    @State private var showUnreleasedWarning = false
    /// Which categories are collapsed on the Game Catalog (sectioned) view. Empty = all expanded.
    @State private var collapsedSections: Set<GameStatus> = []
    @State private var isRefreshingAll = false
    @State private var gameToRate: Game?
    /// Set when a game is moved to Completed; after celebration we may show the rating/play-time prompt.
    @State private var gameJustCompleted: Game?
    /// When set, show a subtle sheet asking if the user wants to add rating or estimated hours.
    @State private var gameToPromptForDetails: Game?
    /// When set, present GameDetailView so user can add rating/hours (e.g. after tapping "Add details" in prompt).
    @State private var gameToOpenForDetails: Game?
    /// Games that were unreleased in Wishlist and are now released after refresh — prompt to move to Backlog.
    @State private var gamesReleasedFromWishlist: [Game] = []

    // MARK: - Derived data

    /// Unique individual platforms across all games (split from combined strings for filter menu), normalized for display (e.g. "PC" not "PC (Microsoft Windows)").
    private var platforms: [String] {
        let all = games.flatMap { Game.platformComponents($0.platform) }.map { Game.displayPlatform(from: $0) }.filter { !$0.isEmpty }
        return Array(Set(all)).sorted()
    }

    /// Unique genres across all games (for filter menu).
    private var genres: [String] {
        Array(Set(games.compactMap(\.genre).filter { !$0.isEmpty })).sorted()
    }

    /// Whether any filter is active.
    private var isFiltered: Bool {
        filterStatus != nil || filterPlatform != nil || filterGenre != nil
    }

    /// Count per status (one pass over games) for the catalog summary row.
    private var statusCounts: [GameStatus: Int] {
        var counts: [GameStatus: Int] = [.playing: 0, .backlog: 0, .wishlist: 0, .completed: 0, .dropped: 0]
        for game in games {
            counts[game.status, default: 0] += 1
        }
        return counts
    }

    /// Show status sections (Now Playing, Backlog, etc.) instead of a single list.
    private var showStatusSections: Bool {
        filterStatus == nil && searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Display + section arrays in one pass to avoid repeated filter/sort work.
    private struct SectionedDisplay {
        var displayed: [Game]
        var nowPlaying: [Game]
        var backlog: [Game]
        var wishlist: [Game]
        var completed: [Game]
        var dropped: [Game]
    }

    /// Games after search/filter/sort plus sections, computed in a single pass.
    private var sectionedDisplay: SectionedDisplay {
        var result = games

        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            result = result.filter { $0.title.lowercased().contains(query) }
        }
        if let status = filterStatus {
            result = result.filter { $0.status == status }
        }
        if let platform = filterPlatform {
            result = result.filter { game in
                Game.platformComponents(game.platform).map { Game.displayPlatform(from: $0) }.contains(platform)
            }
        }
        if let genre = filterGenre {
            result = result.filter { $0.genre == genre }
        }
        switch sortMode {
        case .priority:
            break
        case .criticScore:
            result.sort { ($0.igdbRating ?? -1) > ($1.igdbRating ?? -1) }
        case .releaseDate:
            result.sort { ($0.releaseDate ?? .distantPast) > ($1.releaseDate ?? .distantPast) }
        }

        var nowPlaying: [Game] = []
        var backlog: [Game] = []
        var wishlist: [Game] = []
        var completed: [Game] = []
        var dropped: [Game] = []
        nowPlaying.reserveCapacity(result.count / 5)
        backlog.reserveCapacity(result.count / 5)
        wishlist.reserveCapacity(result.count / 5)
        completed.reserveCapacity(result.count / 5)
        dropped.reserveCapacity(result.count / 5)
        for game in result {
            switch game.status {
            case .playing: nowPlaying.append(game)
            case .backlog: backlog.append(game)
            case .wishlist: wishlist.append(game)
            case .completed: completed.append(game)
            case .dropped: dropped.append(game)
            }
        }
        let sortByRatingThenUpdated: (Game, Game) -> Bool = { g1, g2 in
            let r1 = g1.personalRating ?? -1
            let r2 = g2.personalRating ?? -1
            if r1 != r2 { return r1 > r2 }
            return g1.updatedAt > g2.updatedAt
        }
        completed.sort(by: sortByRatingThenUpdated)
        dropped.sort(by: sortByRatingThenUpdated)

        return SectionedDisplay(
            displayed: result,
            nowPlaying: nowPlaying,
            backlog: backlog,
            wishlist: wishlist,
            completed: completed,
            dropped: dropped
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if games.isEmpty {
                    emptyState
                } else if sectionedDisplay.displayed.isEmpty {
                    noResultsState
                } else {
                    VStack(spacing: 0) {
                        catalogSummaryRow
                        gameList
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
                    Button { showingAddGame = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add game")
                }
                ToolbarItem(placement: .topBarLeading) {
                    filterMenu
                        .accessibilityLabel("Filter and sort games")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    let hasLinkedGames = games.contains { $0.externalId != nil }
                    Button {
                        guard hasLinkedGames, !isRefreshingAll else { return }
                        isRefreshingAll = true
                        Task {
                            let released = await GameSyncService.shared.refreshAllGames(in: modelContext)
                            await MainActor.run {
                                isRefreshingAll = false
                                if !released.isEmpty {
                                    gamesReleasedFromWishlist = released
                                }
                            }
                        }
                    } label: {
                        if isRefreshingAll {
                            ProgressView()
                                .scaleEffect(0.85)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(!hasLinkedGames || isRefreshingAll)
                    .accessibilityLabel(isRefreshingAll ? "Refreshing metadata" : "Refresh metadata for all games")
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
                RatingSheet(game: game) {
                    gameToRate = nil
                }
            }
            .sheet(item: $gameToPromptForDetails) { game in
                AddDetailsPromptSheet(
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

    private func pushWidgetSummaryFromContext() {
        let descriptor = FetchDescriptor<Game>(sortBy: [SortDescriptor(\.priorityPosition)])
        guard let games = try? modelContext.fetch(descriptor) else { return }
        WidgetSummaryStorage.write(WidgetSummaryBuilder.make(from: games))
        WidgetCenter.shared.reloadTimelines(ofKind: "VGBWidget")
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Games Yet", systemImage: "gamecontroller")
        } description: {
            Text("Add a game to start tracking your backlog.")
        }
        .accessibilityLabel("No games yet. Add a game to start tracking your backlog.")
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
                .accessibilityLabel("Clear filters")
            }
        }
        .accessibilityLabel("No matches. No games match the current search or filters.")
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

    // MARK: - Catalog Summary Row

    private var catalogSummaryRow: some View {
        let order: [GameStatus] = [.playing, .backlog, .wishlist, .completed, .dropped]
        let indices = Array(order.indices)
        return HStack(spacing: 0) {
            ForEach(indices, id: \.self) { i in
                let status = order[i]
                let count = statusCounts[status] ?? 0
                VStack(spacing: 2) {
                    Text("\(count)")
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .foregroundStyle(status.color)
                    Text(status.shortLabel)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
    }

    // MARK: - Game List

    private var gameList: some View {
        Group {
            if showStatusSections {
                scrollViewSectionedList
            } else {
                List { singleSection }
            }
        }
        .navigationDestination(for: Game.self) { game in
            GameDetailView(game: game)
        }
    }

    /// Sectioned list in a ScrollView (not List) so drag-and-drop works.
    private var scrollViewSectionedList: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                sectionBlock(status: .playing, games: sectionedDisplay.nowPlaying, isExpanded: !collapsedSections.contains(.playing), onToggle: { withAnimation(.easeInOut(duration: 0.25)) { collapsedSections.formSymmetricDifference([.playing]) } }, onMoveToCompleted: nil) { game in
                    swipeCompleted(game)
                    swipeDropped(game)
                }
                sectionBlock(status: .backlog, games: sectionedDisplay.backlog, isExpanded: !collapsedSections.contains(.backlog), onToggle: { withAnimation(.easeInOut(duration: 0.25)) { collapsedSections.formSymmetricDifference([.backlog]) } }, onMoveToCompleted: nil) { game in
                    swipeCompleted(game)
                    swipeDropped(game)
                }
                sectionBlock(status: .wishlist, games: sectionedDisplay.wishlist, isExpanded: !collapsedSections.contains(.wishlist), onToggle: { withAnimation(.easeInOut(duration: 0.25)) { collapsedSections.formSymmetricDifference([.wishlist]) } }, onMoveToCompleted: nil)
                sectionBlock(status: .completed, games: sectionedDisplay.completed, isExpanded: !collapsedSections.contains(.completed), onToggle: { withAnimation(.easeInOut(duration: 0.25)) { collapsedSections.formSymmetricDifference([.completed]) } }, onMoveToCompleted: onGameMovedToCompleted)
                sectionBlock(status: .dropped, games: sectionedDisplay.dropped, isExpanded: !collapsedSections.contains(.dropped), onToggle: { withAnimation(.easeInOut(duration: 0.25)) { collapsedSections.formSymmetricDifference([.dropped]) } }, onMoveToCompleted: nil)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func sectionBlock(
        status: GameStatus,
        games: [Game],
        isExpanded: Bool,
        onToggle: @escaping () -> Void,
        onMoveToCompleted: ((Game) -> Void)?,
        @ViewBuilder trailingSwipe: (Game) -> some View = { _ in EmptyView() }
    ) -> some View {
        let meta = status.sectionMetadata
        return VStack(alignment: .leading, spacing: 0) {
            SectionHeaderDropZone(
                title: meta.title,
                systemImage: meta.systemImage,
                color: meta.color,
                isExpanded: isExpanded,
                onToggle: onToggle
            )
            if isExpanded {
                if games.isEmpty {
                    Button {
                        addGameInitialStatus = status
                        showingAddGame = true
                    } label: {
                        Label("Add Game", systemImage: "plus.circle.fill")
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundStyle(meta.color)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add game to \(meta.title)")
                } else {
                    ForEach(Array(games.enumerated()), id: \.element.id) { index, game in
                        draggableRow(
                            for: game,
                            targetStatus: status,
                            sectionGames: games,
                            sectionIndex: index,
                            onMoveToCompleted: onMoveToCompleted,
                            rank: status == .completed && index < 3 ? index + 1 : nil,
                            isMostAnticipated: status == .wishlist && index == 0
                        )
                        if game.id != games.last?.id {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    /// Row used in ScrollView sectioned list: draggable via .onDrag, also accepts drops (move to this category or reorder within section); use context menu to change status.
    private func draggableRow(for game: Game, targetStatus: GameStatus, sectionGames: [Game], sectionIndex: Int, onMoveToCompleted: ((Game) -> Void)?, rank: Int? = nil, isMostAnticipated: Bool = false) -> some View {
        DraggableCatalogRow(
            game: game,
            targetStatus: targetStatus,
            sectionGames: sectionGames,
            sectionIndex: sectionIndex,
            onMoveToCompleted: onMoveToCompleted,
            rank: rank,
            isMostAnticipated: isMostAnticipated,
            onHandleRowDrop: { id, status, games, idx, onCompleted in
                handleRowDrop(droppedId: id, targetStatus: status, sectionGames: games, destinationIndex: idx, onMoveToCompleted: onCompleted, onUnreleasedWarning: { showUnreleasedWarning = true })
            },
            onRateTap: { gameToRate = game },
            contextMenuContent: moveToContextMenu
        )
    }

    /// Handles drop on a row: reorder within section if same status, otherwise move to this category.
    private func handleRowDrop(droppedId: UUID, targetStatus: GameStatus, sectionGames: [Game], destinationIndex: Int, onMoveToCompleted: ((Game) -> Void)?, onUnreleasedWarning: (() -> Void)? = nil) {
        var descriptor = FetchDescriptor<Game>(predicate: #Predicate<Game> { $0.id == droppedId })
        descriptor.fetchLimit = 1
        guard let droppedGame = try? modelContext.fetch(descriptor).first else { return }
        let sameSection = droppedGame.status == targetStatus
        let reorderable: Set<GameStatus> = [.playing, .backlog, .wishlist, .completed, .dropped]
        if sameSection, reorderable.contains(targetStatus), let sourceIndex = sectionGames.firstIndex(where: { $0.id == droppedId }) {
            if sourceIndex == destinationIndex { return }
            // When moving down, "drop on row N" means "put item below row N" → insert after N → toOffset N+1.
            // When moving up, "drop on row N" means "put item at row N" → toOffset N.
            let toOffset: Int
            if sourceIndex < destinationIndex {
                toOffset = min(destinationIndex + 1, sectionGames.count)
            } else {
                toOffset = destinationIndex
            }
            reorderInSection(games: sectionGames, from: IndexSet(integer: sourceIndex), to: toOffset, targetStatus: targetStatus)
            Haptic.dropSnap.play()
        } else {
            applyDropToGame(droppedId, targetStatus: targetStatus, onMoveToCompleted: onMoveToCompleted, onUnreleasedWarning: onUnreleasedWarning)
            Haptic.dropSnap.play()
        }
    }

    private func applyDropToGame(_ gameId: UUID, targetStatus: GameStatus, onMoveToCompleted: ((Game) -> Void)?, onUnreleasedWarning: (() -> Void)? = nil) {
        var descriptor = FetchDescriptor<Game>(predicate: #Predicate<Game> { $0.id == gameId })
        descriptor.fetchLimit = 1
        guard let game = try? modelContext.fetch(descriptor).first else { return }
        // Unreleased games can only be in Wishlist
        let effectiveStatus = game.isUnreleased ? GameStatus.wishlist : targetStatus
        if game.isUnreleased && targetStatus != .wishlist {
            onUnreleasedWarning?()
        }
        game.status = effectiveStatus
        game.updatedAt = Date()
        if effectiveStatus == .completed {
            onMoveToCompleted?(game)
        }
    }

    /// Call when a game has just been moved to Completed (from drop, context menu, or swipe).
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

    /// Single list (when filtering by status or searching).
    private var singleSection: some View {
        Section {
            ForEach(sectionedDisplay.displayed) { game in
                row(for: game, showLeading: true, showTrailing: true) {
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
                statusSectionHeader(status)
            }
        }
    }

    /// Header for the filtered list when a status filter is active (matches section bucket style).
    private func statusSectionHeader(_ status: GameStatus) -> some View {
        let meta = status.sectionMetadata
        return Label(meta.title, systemImage: meta.systemImage)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(meta.color)
    }

    private func row(
        for game: Game,
        showLeading: Bool,
        showTrailing: Bool,
        targetStatus: GameStatus? = nil,
        onMoveToCompleted: (() -> Void)? = nil,
        @ViewBuilder trailingSwipe: () -> some View
    ) -> some View {
        rowContent(for: game, showLeading: showLeading, showTrailing: showTrailing, trailingSwipe: trailingSwipe)
            .modifier(RowDropModifier(
                targetStatus: targetStatus,
                onMoveToCompleted: onMoveToCompleted,
                modelContext: modelContext
            ))
    }

    private func rowContent(
        for game: Game,
        showLeading: Bool,
        showTrailing: Bool,
        @ViewBuilder trailingSwipe: () -> some View
    ) -> some View {
        NavigationLink(value: game) {
            GameRowView(game: game, onRateTap: { gameToRate = game }).equatable()
        }
        .draggable(game.id.uuidString)
        .contextMenu {
            moveToContextMenu(for: game)
        }
        .swipeActions(edge: .leading) {
            if showLeading && !game.isUnreleased { swipePlayNow(game) }
        }
        .swipeActions(edge: .trailing) {
            if showTrailing {
                trailingSwipe()
            } else if !game.isUnreleased {
                swipeCompleted(game)
                swipeDropped(game)
            }
        }
    }

    @ViewBuilder
    private func moveToContextMenu(for game: Game) -> some View {
        ForEach(GameStatus.allCases, id: \.id) { status in
            if game.status != status {
                Button {
                    if game.isUnreleased && status != .wishlist {
                        showUnreleasedWarning = true
                    } else {
                        game.status = status
                        game.updatedAt = Date()
                        if status == .completed {
                            onGameMovedToCompleted(game)
                        }
                    }
                }                 label: {
                    Label("Move to \(status.rawValue)", systemImage: status.sectionIcon)
                }
            }
        }
    }

    private func reorderInSection(games: [Game], from source: IndexSet, to destination: Int, targetStatus: GameStatus) {
        var newOrder = games
        newOrder.move(fromOffsets: source, toOffset: destination)
        let sd = sectionedDisplay
        let reordered: [Game] = switch targetStatus {
        case .playing: newOrder + sd.backlog + sd.wishlist + sd.completed + sd.dropped
        case .backlog: sd.nowPlaying + newOrder + sd.wishlist + sd.completed + sd.dropped
        case .wishlist: sd.nowPlaying + sd.backlog + newOrder + sd.completed + sd.dropped
        case .completed: sd.nowPlaying + sd.backlog + sd.wishlist + newOrder + sd.dropped
        case .dropped: sd.nowPlaying + sd.backlog + sd.wishlist + sd.completed + newOrder
        }
        withAnimation(.easeOut(duration: 0.18)) {
            for (index, game) in reordered.enumerated() {
                game.priorityPosition = index
            }
        }
    }

    // MARK: - Actions

    private func clearFilters() {
        filterStatus = nil
        filterPlatform = nil
        filterGenre = nil
    }

    private func delete(at offsets: IndexSet) {
        let toDelete = offsets.map { sectionedDisplay.displayed[$0] }
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
            gameJustCompleted = game
            triggerCelebration()
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
        var ordered = sectionedDisplay.displayed
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, game) in ordered.enumerated() {
            game.priorityPosition = index
        }
    }
}

// MARK: - Drop delegate (hides green + by using .move, drives highlight)

private struct CatalogRowDropDelegate: DropDelegate {
    @Binding var isTargeted: Bool
    let targetStatus: GameStatus
    let sectionGames: [Game]
    let sectionIndex: Int
    let onMoveToCompleted: ((Game) -> Void)?
    let onHandleRowDrop: (UUID, GameStatus, [Game], Int, ((Game) -> Void)?) -> Void

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func dropEntered(info: DropInfo) {
        isTargeted = true
        // Immediate light haptic so user feels the drop target; prepare dropSnap for instant feedback on release.
        let light = UIImpactFeedbackGenerator(style: .light)
        light.impactOccurred()
        UIImpactFeedbackGenerator(style: .medium).prepare()
    }

    func dropExited(info: DropInfo) {
        isTargeted = false
    }

    func performDrop(info: DropInfo) -> Bool {
        let providers = info.itemProviders(for: [.plainText])
        guard let provider = providers.first else { return false }
        isTargeted = false
        provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let str = object as? String,
                  let droppedId = UUID(uuidString: str) else { return }
            DispatchQueue.main.async {
                onHandleRowDrop(droppedId, targetStatus, sectionGames, sectionIndex, onMoveToCompleted)
            }
        }
        return true
    }
}

// MARK: - Draggable catalog row (highlight on drop target)

private struct DraggableCatalogRow<ContextMenuContent: View>: View {
    let game: Game
    let targetStatus: GameStatus
    let sectionGames: [Game]
    let sectionIndex: Int
    let onMoveToCompleted: ((Game) -> Void)?
    let rank: Int?
    let isMostAnticipated: Bool
    let onHandleRowDrop: (UUID, GameStatus, [Game], Int, ((Game) -> Void)?) -> Void
    let onRateTap: (() -> Void)?
    @ViewBuilder let contextMenuContent: (Game) -> ContextMenuContent

    @State private var isTargeted = false

    var body: some View {
        ZStack(alignment: .leading) {
            // Full-width highlight behind content; animated for smooth snap feedback
            RoundedRectangle(cornerRadius: 10)
                .fill(isTargeted ? Color.accentColor.opacity(0.18) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isTargeted ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 2)
                )
                .frame(maxWidth: .infinity)

            NavigationLink(value: game) {
                GameRowView(game: game, rank: rank, isMostAnticipated: isMostAnticipated, onRateTap: onRateTap).equatable()
            }
            .tint(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .animation(.easeOut(duration: 0.1), value: isTargeted)
        .onDrag {
            NSItemProvider(object: game.id.uuidString as NSString)
        }
        .onDrop(of: [.plainText], delegate: CatalogRowDropDelegate(
            isTargeted: $isTargeted,
            targetStatus: targetStatus,
            sectionGames: sectionGames,
            sectionIndex: sectionIndex,
            onMoveToCompleted: onMoveToCompleted,
            onHandleRowDrop: onHandleRowDrop
        ))
        .contextMenu {
            contextMenuContent(game)
        }
    }
}

// MARK: - Row

private struct GameRowView: View, Equatable {
    let game: Game
    /// Stored for Equatable so we don't touch main-actor-isolated Game in ==.
    private let gameId: UUID
    /// Top-3 rank in Completed section (1 = gold, 2 = silver, 3 = bronze).
    var rank: Int? = nil
    /// True for #1 on Wishlist (priority order).
    var isMostAnticipated: Bool = false
    /// Called when user taps the personal rating star. Nil = rating not tappable.
    var onRateTap: (() -> Void)? = nil

    init(game: Game, rank: Int? = nil, isMostAnticipated: Bool = false, onRateTap: (() -> Void)? = nil) {
        self.game = game
        self.gameId = game.id
        self.rank = rank
        self.isMostAnticipated = isMostAnticipated
        self.onRateTap = onRateTap
    }

    nonisolated static func == (lhs: GameRowView, rhs: GameRowView) -> Bool {
        lhs.gameId == rhs.gameId && lhs.rank == rhs.rank && lhs.isMostAnticipated == rhs.isMostAnticipated
    }

    @ViewBuilder
    private var personalRatingPill: some View {
        if let rating = game.personalRating {
            ratingPill(icon: "star.fill", value: "You \(rating)", color: .blue)
        } else {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.quaternary)
                Text("Unrated")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

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
                                .font(.system(size: 12, weight: .regular, design: .rounded))
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
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(.tertiary)
                    }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(game.title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(game.displayPlatform)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .opacity(game.platform.isEmpty ? 0 : 1)

                if !game.isUnreleased || rank.map({ (1...3).contains($0) }) == true {
                    HStack(alignment: .center, spacing: 12) {
                        if !game.isUnreleased {
                            HStack(alignment: .center, spacing: 12) {
                                if let rating = game.igdbRating {
                                    ratingPill(icon: "star.fill", value: "\(rating)", color: .orange)
                                }
                                if let onTap = onRateTap {
                                    Button {
                                        onTap()
                                    } label: {
                                        personalRatingPill
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityHint("Tap to set or change your rating")
                                } else {
                                    personalRatingPill
                                }
                            }
                        }
                        Spacer(minLength: 8)
                        if let rank, (1...3).contains(rank) {
                            rankBadge(rank: rank)
                        }
                    }
                }

                HStack(spacing: 6) {
                    if game.isUnreleased {
                        UnreleasedBadge()
                    }

                    if isMostAnticipated {
                        Label("Most Anticipated", systemImage: "star.fill")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.pink)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.pink.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func ratingPill(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(color)
        }
    }

    @ViewBuilder
    private func rankBadge(rank: Int) -> some View {
        let (icon, color): (String, Color) = switch rank {
        case 1: ("trophy.fill", .yellow)
        case 2: ("2.circle.fill", Color(white: 0.75))
        case 3: ("3.circle.fill", .brown)
        default: ("circle.fill", .gray)
        }
        Image(systemName: icon)
            .font(.system(size: 12, weight: .regular, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.2))
            .clipShape(Capsule())
    }
}

// MARK: - Unreleased Badge

private struct UnreleasedBadge: View {
    var body: some View {
        Text("Unreleased")
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(.indigo.opacity(0.15))
            .foregroundStyle(.indigo)
            .clipShape(Capsule())
    }
}

// MARK: - Section header (tap to expand/collapse; drops on headers disabled)

private struct SectionHeaderDropZone: View {
    let title: String
    let systemImage: String
    let color: Color
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
            Spacer(minLength: 0)
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}

// MARK: - Row drop (cross-category drag)

private struct RowDropModifier: ViewModifier {
    let targetStatus: GameStatus?
    let onMoveToCompleted: (() -> Void)?
    let modelContext: ModelContext

    func body(content: Content) -> some View {
        if let targetStatus {
            content.dropDestination(for: String.self) { uuidStrings, _ in
                #if DEBUG
                print("[VGB Drop] dropDestination — targetStatus=\(targetStatus.rawValue), count=\(uuidStrings.count)")
                #endif
                for uuidString in uuidStrings {
                    guard let droppedId = UUID(uuidString: uuidString) else { continue }
                    var descriptor = FetchDescriptor<Game>(predicate: #Predicate<Game> { $0.id == droppedId })
                    descriptor.fetchLimit = 1
                    guard let game = try? modelContext.fetch(descriptor).first else { continue }
                    game.status = targetStatus
                    game.updatedAt = Date()
                }
                if targetStatus == .completed, !uuidStrings.isEmpty {
                    onMoveToCompleted?()
                }
                return true
            } isTargeted: { _ in }
        } else {
            content
        }
    }
}

// MARK: - Add details prompt (completed game without rating or play time)

private struct AddDetailsPromptSheet: View {
    let game: Game
    let onAdd: () -> Void
    let onLater: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Add a rating or estimated hours for \(game.title) to get more from Stats and Rankings.")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack(spacing: 12) {
                    Button("Maybe later") {
                        onLater()
                    }
                    .buttonStyle(.bordered)

                    Button("Add details") {
                        onAdd()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top, 8)
            }
            .padding(.vertical, 24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { onLater() }
                }
            }
        }
    }
}

#Preview {
    BacklogListView()
        .modelContainer(for: Game.self, inMemory: true)
}
