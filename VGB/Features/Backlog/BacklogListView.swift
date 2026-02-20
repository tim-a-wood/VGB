import SwiftUI
import SwiftData
import UniformTypeIdentifiers

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

    // MARK: - Derived data

    /// Splits a combined platform string (e.g. "PS5, PC" from IGDB) into individual platforms.
    private static func platformComponents(_ platformString: String) -> [String] {
        let trimmed = platformString.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        return trimmed
            .components(separatedBy: CharacterSet(charactersIn: ",|/"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// Unique individual platforms across all games (split from combined strings for filter menu), normalized for display (e.g. "PC" not "PC (Microsoft Windows)").
    private var platforms: [String] {
        let all = games.flatMap { Self.platformComponents($0.platform) }.map { Game.displayPlatform(from: $0) }.filter { !$0.isEmpty }
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
                Self.platformComponents(game.platform).map { Game.displayPlatform(from: $0) }.contains(platform)
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
                    gameList
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
                            await GameSyncService.shared.refreshAllGames(in: modelContext)
                            await MainActor.run { isRefreshingAll = false }
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
        }
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
                sectionBlock(title: "Now Playing", systemImage: "play.fill", color: .blue, targetStatus: .playing, games: sectionedDisplay.nowPlaying, isExpanded: !collapsedSections.contains(.playing), onToggle: { withAnimation(.easeInOut(duration: 0.25)) { collapsedSections.formSymmetricDifference([.playing]) } }, onMoveToCompleted: nil) { game in
                    swipeCompleted(game)
                    swipeDropped(game)
                }
                sectionBlock(title: "Backlog", systemImage: "list.bullet", color: .gray, targetStatus: .backlog, games: sectionedDisplay.backlog, isExpanded: !collapsedSections.contains(.backlog), onToggle: { withAnimation(.easeInOut(duration: 0.25)) { collapsedSections.formSymmetricDifference([.backlog]) } }, onMoveToCompleted: nil) { game in
                    swipeCompleted(game)
                    swipeDropped(game)
                }
                sectionBlock(title: "Wishlist", systemImage: "heart.fill", color: .purple, targetStatus: .wishlist, games: sectionedDisplay.wishlist, isExpanded: !collapsedSections.contains(.wishlist), onToggle: { withAnimation(.easeInOut(duration: 0.25)) { collapsedSections.formSymmetricDifference([.wishlist]) } }, onMoveToCompleted: nil)
                sectionBlock(title: "Completed", systemImage: "checkmark.circle.fill", color: .green, targetStatus: .completed, games: sectionedDisplay.completed, isExpanded: !collapsedSections.contains(.completed), onToggle: { withAnimation(.easeInOut(duration: 0.25)) { collapsedSections.formSymmetricDifference([.completed]) } }, onMoveToCompleted: triggerCelebration)
                sectionBlock(title: "Dropped", systemImage: "xmark.circle.fill", color: .orange, targetStatus: .dropped, games: sectionedDisplay.dropped, isExpanded: !collapsedSections.contains(.dropped), onToggle: { withAnimation(.easeInOut(duration: 0.25)) { collapsedSections.formSymmetricDifference([.dropped]) } }, onMoveToCompleted: nil)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func sectionBlock(
        title: String,
        systemImage: String,
        color: Color,
        targetStatus: GameStatus,
        games: [Game],
        isExpanded: Bool,
        onToggle: @escaping () -> Void,
        onMoveToCompleted: (() -> Void)?,
        @ViewBuilder trailingSwipe: (Game) -> some View = { _ in EmptyView() }
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeaderDropZone(
                title: title,
                systemImage: systemImage,
                color: color,
                isExpanded: isExpanded,
                onToggle: onToggle
            )
            if isExpanded {
                if games.isEmpty {
                    Button {
                        addGameInitialStatus = targetStatus
                        showingAddGame = true
                    } label: {
                        Label("Add Game", systemImage: "plus.circle.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(color)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add game to \(title)")
                } else {
                    ForEach(Array(games.enumerated()), id: \.element.id) { index, game in
                        draggableRow(
                            for: game,
                            targetStatus: targetStatus,
                            sectionGames: games,
                            sectionIndex: index,
                            onMoveToCompleted: onMoveToCompleted,
                            rank: targetStatus == .completed && index < 3 ? index + 1 : nil,
                            isMostAnticipated: targetStatus == .wishlist && index == 0
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
    private func draggableRow(for game: Game, targetStatus: GameStatus, sectionGames: [Game], sectionIndex: Int, onMoveToCompleted: (() -> Void)?, rank: Int? = nil, isMostAnticipated: Bool = false) -> some View {
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
            contextMenuContent: moveToContextMenu
        )
    }

    /// Handles drop on a row: reorder within section if same status, otherwise move to this category.
    private func handleRowDrop(droppedId: UUID, targetStatus: GameStatus, sectionGames: [Game], destinationIndex: Int, onMoveToCompleted: (() -> Void)?, onUnreleasedWarning: (() -> Void)? = nil) {
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

    private func applyDropToGame(_ gameId: UUID, targetStatus: GameStatus, onMoveToCompleted: (() -> Void)?, onUnreleasedWarning: (() -> Void)? = nil) {
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
            onMoveToCompleted?()
        }
    }

    private func triggerCelebration() {
        Haptic.success.play()
        withAnimation { showCelebration = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showCelebration = false }
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
        let (title, systemImage, color) = statusSectionTitleAndIcon(status)
        return Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(color)
    }

    private func statusSectionTitleAndIcon(_ status: GameStatus) -> (title: String, systemImage: String, color: Color) {
        switch status {
        case .playing: return ("Now Playing", "play.fill", .blue)
        case .backlog: return ("Backlog", "list.bullet", .gray)
        case .wishlist: return ("Wishlist", "heart.fill", .purple)
        case .completed: return ("Completed", "checkmark.circle.fill", .green)
        case .dropped: return ("Dropped", "xmark.circle.fill", .orange)
        }
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
            GameRowView(game: game).equatable()
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
                            triggerCelebration()
                        }
                    }
                } label: {
                    Label("Move to \(status.rawValue)", systemImage: statusIcon(status))
                }
            }
        }
    }

    private func statusIcon(_ status: GameStatus) -> String {
        switch status {
        case .wishlist: return "heart.fill"
        case .backlog: return "list.bullet"
        case .playing: return "play.fill"
        case .completed: return "checkmark.circle.fill"
        case .dropped: return "xmark.circle.fill"
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
        withAnimation(.easeInOut(duration: 0.25)) {
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
    let onMoveToCompleted: (() -> Void)?
    let onHandleRowDrop: (UUID, GameStatus, [Game], Int, (() -> Void)?) -> Void

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func dropEntered(info: DropInfo) {
        isTargeted = true
    }

    func dropExited(info: DropInfo) {
        isTargeted = false
    }

    func performDrop(info: DropInfo) -> Bool {
        let providers = info.itemProviders(for: [.plainText])
        guard let provider = providers.first else { return false }
        provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let str = object as? String,
                  let droppedId = UUID(uuidString: str) else { return }
            DispatchQueue.main.async {
                onHandleRowDrop(droppedId, targetStatus, sectionGames, sectionIndex, onMoveToCompleted)
                isTargeted = false
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
    let onMoveToCompleted: (() -> Void)?
    let rank: Int?
    let isMostAnticipated: Bool
    let onHandleRowDrop: (UUID, GameStatus, [Game], Int, (() -> Void)?) -> Void
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
                GameRowView(game: game, rank: rank, isMostAnticipated: isMostAnticipated).equatable()
            }
            .tint(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.2), value: isTargeted)
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

    init(game: Game, rank: Int? = nil, isMostAnticipated: Bool = false) {
        self.game = game
        self.gameId = game.id
        self.rank = rank
        self.isMostAnticipated = isMostAnticipated
    }

    nonisolated static func == (lhs: GameRowView, rhs: GameRowView) -> Bool {
        lhs.gameId == rhs.gameId && lhs.rank == rhs.rank && lhs.isMostAnticipated == rhs.isMostAnticipated
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
                    .truncationMode(.tail)

                Text(game.displayPlatform)
                    .font(.caption)
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
                                if let rating = game.personalRating {
                                    ratingPill(icon: "star.fill", value: "You \(rating)", color: .blue)
                                } else {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .font(.caption)
                                            .foregroundStyle(.quaternary)
                                        Text("Unrated")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
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
                            .font(.caption2.weight(.semibold))
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
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.caption)
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
            .font(.caption)
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
            .font(.caption2.weight(.medium))
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
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
            Spacer(minLength: 0)
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.caption.weight(.semibold))
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

#Preview {
    BacklogListView()
        .modelContainer(for: Game.self, inMemory: true)
}
