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
    @State private var sortMode: SortMode = .priority
    @State private var filterStatus: GameStatus?
    @State private var filterPlatform: String?
    @State private var filterGenre: String?
    @State private var searchText = ""
    @State private var showCelebration = false
    /// Which categories are collapsed on the Game Catalog (sectioned) view. Empty = all expanded.
    @State private var collapsedSections: Set<GameStatus> = []

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

    /// Unique individual platforms across all games (split from combined strings for filter menu).
    private var platforms: [String] {
        let all = games.flatMap { Self.platformComponents($0.platform) }
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

    /// Games currently being played (for the pinned section).
    private var nowPlaying: [Game] {
        displayedGames.filter { $0.status == .playing }
    }

    /// Games in backlog (when showing status sections).
    private var backlogGames: [Game] {
        displayedGames.filter { $0.status == .backlog }
    }

    /// Games completed (when showing status sections), ordered by user rating (highest first).
    private var completedGames: [Game] {
        displayedGames
            .filter { $0.status == .completed }
            .sorted { g1, g2 in
                let r1 = g1.personalRating ?? -1
                let r2 = g2.personalRating ?? -1
                if r1 != r2 { return r1 > r2 }
                return g1.updatedAt > g2.updatedAt
            }
    }

    /// Games dropped (when showing status sections), ordered by user rating (highest first).
    private var droppedGames: [Game] {
        displayedGames
            .filter { $0.status == .dropped }
            .sorted { g1, g2 in
                let r1 = g1.personalRating ?? -1
                let r2 = g2.personalRating ?? -1
                if r1 != r2 { return r1 > r2 }
                return g1.updatedAt > g2.updatedAt
            }
    }

    /// Games on wishlist (when showing status sections).
    private var wishlistGames: [Game] {
        displayedGames.filter { $0.status == .wishlist }
    }

    /// Show status sections (Now Playing, Backlog, etc.) instead of a single list.
    private var showStatusSections: Bool {
        filterStatus == nil && searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Games after applying search, filters, and sort.
    private var displayedGames: [Game] {
        var result = games

        // Text search
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            result = result.filter { $0.title.lowercased().contains(query) }
        }

        // Status filter
        if let status = filterStatus {
            result = result.filter { $0.status == status }
        }

        // Platform filter (match if the game's platform list contains the selected platform)
        if let platform = filterPlatform {
            result = result.filter { game in
                Self.platformComponents(game.platform).contains(platform)
            }
        }

        // Genre filter
        if let genre = filterGenre {
            result = result.filter { $0.genre == genre }
        }

        // Sort
        switch sortMode {
        case .priority:
            break // already sorted by priorityPosition from @Query
        case .criticScore:
            result.sort { ($0.igdbRating ?? -1) > ($1.igdbRating ?? -1) }
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
            .navigationTitle("Game Catalog")
            .searchable(text: $searchText, prompt: "Search games")
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
            }
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
                if !nowPlaying.isEmpty {
                    sectionBlock(title: "Now Playing", systemImage: "play.fill", color: .blue, targetStatus: .playing, games: nowPlaying, isExpanded: !collapsedSections.contains(.playing), onToggle: { withAnimation(.easeInOut(duration: 0.25)) { collapsedSections.formSymmetricDifference([.playing]) } }, onMoveToCompleted: nil) { game in
                        swipeCompleted(game)
                        swipeDropped(game)
                    }
                }
                if !backlogGames.isEmpty {
                    sectionBlock(title: "Backlog", systemImage: "list.bullet", color: .gray, targetStatus: .backlog, games: backlogGames, isExpanded: !collapsedSections.contains(.backlog), onToggle: { withAnimation(.easeInOut(duration: 0.25)) { collapsedSections.formSymmetricDifference([.backlog]) } }, onMoveToCompleted: nil) { game in
                        swipeCompleted(game)
                        swipeDropped(game)
                    }
                }
                if !wishlistGames.isEmpty {
                    sectionBlock(title: "Wishlist", systemImage: "heart.fill", color: .purple, targetStatus: .wishlist, games: wishlistGames, isExpanded: !collapsedSections.contains(.wishlist), onToggle: { withAnimation(.easeInOut(duration: 0.25)) { collapsedSections.formSymmetricDifference([.wishlist]) } }, onMoveToCompleted: nil)
                }
                if !completedGames.isEmpty {
                    sectionBlock(title: "Completed", systemImage: "checkmark.circle.fill", color: .green, targetStatus: .completed, games: completedGames, isExpanded: !collapsedSections.contains(.completed), onToggle: { withAnimation(.easeInOut(duration: 0.25)) { collapsedSections.formSymmetricDifference([.completed]) } }, onMoveToCompleted: triggerCelebration)
                }
                if !droppedGames.isEmpty {
                    sectionBlock(title: "Dropped", systemImage: "xmark.circle.fill", color: .orange, targetStatus: .dropped, games: droppedGames, isExpanded: !collapsedSections.contains(.dropped), onToggle: { withAnimation(.easeInOut(duration: 0.25)) { collapsedSections.formSymmetricDifference([.dropped]) } }, onMoveToCompleted: nil)
                }
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
                targetStatus: targetStatus,
                isExpanded: isExpanded,
                onToggle: onToggle,
                onMoveToCompleted: onMoveToCompleted,
                modelContext: modelContext
            )
            if isExpanded {
                ForEach(Array(games.enumerated()), id: \.element.id) { index, game in
                    draggableRow(
                        for: game,
                        targetStatus: targetStatus,
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
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    /// Row used in ScrollView sectioned list: draggable via .onDrag, also accepts drops (move to this category); use context menu to change status.
    private func draggableRow(for game: Game, targetStatus: GameStatus, onMoveToCompleted: (() -> Void)?, rank: Int? = nil, isMostAnticipated: Bool = false) -> some View {
        NavigationLink(value: game) {
            GameRowView(game: game, rank: rank, isMostAnticipated: isMostAnticipated)
        }
        .tint(.primary)
        .onDrag {
            NSItemProvider(object: game.id.uuidString as NSString)
        }
        .onDrop(of: [.plainText], isTargeted: nil) { providers in
            guard let provider = providers.first else { return false }
            provider.loadObject(ofClass: NSString.self) { object, _ in
                guard let str = object as? String,
                      let droppedId = UUID(uuidString: str) else { return }
                DispatchQueue.main.async {
                    applyDropToGame(droppedId, targetStatus: targetStatus, onMoveToCompleted: onMoveToCompleted)
                }
            }
            return true
        }
        .contextMenu {
            moveToContextMenu(for: game)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func applyDropToGame(_ gameId: UUID, targetStatus: GameStatus, onMoveToCompleted: (() -> Void)?) {
        var descriptor = FetchDescriptor<Game>(predicate: #Predicate<Game> { $0.id == gameId })
        descriptor.fetchLimit = 1
        guard let game = try? modelContext.fetch(descriptor).first else { return }
        game.status = targetStatus
        game.updatedAt = Date()
        if targetStatus == .completed {
            onMoveToCompleted?()
        }
    }

    /// Sections by status (Now Playing, Backlog, Completed, Dropped, Wishlist) when no filter/search.
    private var statusSections: some View {
        Group {
            if !nowPlaying.isEmpty {
                statusSection(title: "Now Playing", systemImage: "play.fill", color: .blue, targetStatus: .playing, games: nowPlaying, showLeading: false, showTrailing: true, onMoveToCompleted: nil) { game in
                    swipeCompleted(game)
                    swipeDropped(game)
                }
            }
            if !backlogGames.isEmpty {
                statusSection(title: "Backlog", systemImage: "list.bullet", color: .gray, targetStatus: .backlog, games: backlogGames, showLeading: true, showTrailing: true, reorderable: true, onMoveToCompleted: nil) { game in
                    swipeCompleted(game)
                    swipeDropped(game)
                }
            }
            if !wishlistGames.isEmpty {
                statusSection(title: "Wishlist", systemImage: "heart.fill", color: .purple, targetStatus: .wishlist, games: wishlistGames, showLeading: true, showTrailing: false, onMoveToCompleted: nil)
            }
            if !completedGames.isEmpty {
                statusSection(title: "Completed", systemImage: "checkmark.circle.fill", color: .green, targetStatus: .completed, games: completedGames, showLeading: true, showTrailing: false, onMoveToCompleted: triggerCelebration)
            }
            if !droppedGames.isEmpty {
                statusSection(title: "Dropped", systemImage: "xmark.circle.fill", color: .orange, targetStatus: .dropped, games: droppedGames, showLeading: true, showTrailing: false, onMoveToCompleted: nil)
            }
        }
    }

    private func triggerCelebration() {
        withAnimation { showCelebration = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showCelebration = false }
        }
    }

    /// Single list (when filtering by status or searching).
    private var singleSection: some View {
        Section {
            ForEach(displayedGames) { game in
                row(for: game, showLeading: true, showTrailing: true) {
                    swipeCompleted(game)
                    swipeDropped(game)
                }
            }
            .onMove { source, destination in
                if sortMode == .priority { reorder(from: source, to: destination) }
            }
            .onDelete(perform: delete)
        }
    }

    private func statusSection(
        title: String,
        systemImage: String,
        color: Color,
        targetStatus: GameStatus,
        games: [Game],
        showLeading: Bool = false,
        showTrailing: Bool = false,
        reorderable: Bool = false,
        onMoveToCompleted: (() -> Void)? = nil,
        @ViewBuilder trailingSwipe: @escaping (Game) -> some View = { _ in EmptyView() }
    ) -> some View {
        Section {
            ForEach(games) { game in
                row(
                    for: game,
                    showLeading: showLeading,
                    showTrailing: showTrailing,
                    targetStatus: targetStatus,
                    onMoveToCompleted: onMoveToCompleted
                ) {
                    trailingSwipe(game)
                }
            }
            .onDelete { offsets in
                deleteInSection(games: games, at: offsets)
            }
        } header: {
            SectionHeaderDropZone(
                title: title,
                systemImage: systemImage,
                color: color,
                targetStatus: targetStatus,
                isExpanded: true,
                onToggle: {},
                onMoveToCompleted: onMoveToCompleted,
                modelContext: modelContext
            )
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
            GameRowView(game: game)
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
                    game.status = status
                    game.updatedAt = Date()
                    if status == .completed {
                        triggerCelebration()
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

    /// Applies a drop: updates status of dragged games. Call from MainActor.
    private func applyDrop(uuidStrings: [String], targetStatus: GameStatus, onMoveToCompleted: (() -> Void)?) -> Bool {
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
    }

    private func reorderInSection(games: [Game], from source: IndexSet, to destination: Int) {
        var newOrder = games
        newOrder.move(fromOffsets: source, toOffset: destination)
        let reordered: [Game] = nowPlaying + newOrder + wishlistGames + completedGames + droppedGames
        for (index, game) in reordered.enumerated() {
            game.priorityPosition = index
        }
    }

    private func deleteInSection(games: [Game], at offsets: IndexSet) {
        let toDelete = offsets.map { games[$0] }
        for game in toDelete {
            modelContext.delete(game)
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
    /// Top-3 rank in Completed section (1 = gold, 2 = silver, 3 = bronze).
    var rank: Int? = nil
    /// True for #1 on Wishlist (priority order).
    var isMostAnticipated: Bool = false

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

                HStack(spacing: 8) {
                    if !game.platform.isEmpty {
                        Text(game.platform)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    if let rating = game.igdbRating {
                        Label("\(rating)", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                HStack(spacing: 6) {
                    StatusBadge(status: game.status)

                    if game.isUnreleased {
                        UnreleasedBadge()
                    }

                    if let rank, (1...3).contains(rank) {
                        rankBadge(rank: rank)
                    }

                    if isMostAnticipated {
                        Label("Most Anticipated", systemImage: "star.fill")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.pink)
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

    private var color: Color { status.color }
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

// MARK: - Section header as drop zone (uses .onDrop to match .onDrag NSItemProvider)

private struct SectionHeaderDropZone: View {
    let title: String
    let systemImage: String
    let color: Color
    let targetStatus: GameStatus
    let isExpanded: Bool
    let onToggle: () -> Void
    let onMoveToCompleted: (() -> Void)?
    let modelContext: ModelContext

    @State private var isTargeted = false

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
        .background(isTargeted ? color.opacity(0.25) : Color(.tertiarySystemGroupedBackground))
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
        .onDrop(of: [.plainText], isTargeted: $isTargeted) { providers in
                guard let provider = providers.first else { return false }
                provider.loadObject(ofClass: NSString.self) { object, _ in
                    guard let str = object as? String,
                          let droppedId = UUID(uuidString: str) else { return }
                    DispatchQueue.main.async {
                        applyDrop(gameId: droppedId)
                    }
                }
                return true
            }
    }

    private func applyDrop(gameId: UUID) {
        var descriptor = FetchDescriptor<Game>(predicate: #Predicate<Game> { $0.id == gameId })
        descriptor.fetchLimit = 1
        guard let game = try? modelContext.fetch(descriptor).first else { return }
        game.status = targetStatus
        game.updatedAt = Date()
        if targetStatus == .completed {
            onMoveToCompleted?()
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
                print("[VGB Drop] dropDestination action called — targetStatus=\(targetStatus.rawValue), uuidStrings.count=\(uuidStrings.count), uuidStrings=\(uuidStrings)")
                for uuidString in uuidStrings {
                    guard let droppedId = UUID(uuidString: uuidString) else {
                        print("[VGB Drop]   skip: invalid UUID '\(uuidString)'")
                        continue
                    }
                    var descriptor = FetchDescriptor<Game>(predicate: #Predicate<Game> { $0.id == droppedId })
                    descriptor.fetchLimit = 1
                    guard let game = try? modelContext.fetch(descriptor).first else {
                        print("[VGB Drop]   skip: no game found for id \(droppedId)")
                        continue
                    }
                    let oldStatus = game.status
                    game.status = targetStatus
                    game.updatedAt = Date()
                    print("[VGB Drop]   updated game '\(game.title)' \(oldStatus.rawValue) → \(targetStatus.rawValue)")
                }
                if targetStatus == .completed, !uuidStrings.isEmpty {
                    onMoveToCompleted?()
                }
                print("[VGB Drop] returning true")
                return true
            } isTargeted: { isTargeted in
                print("[VGB Drop] isTargeted(\(targetStatus.rawValue)) = \(isTargeted)")
            }
        } else {
            content
        }
    }
}

#Preview {
    BacklogListView()
        .modelContainer(for: Game.self, inMemory: true)
}
