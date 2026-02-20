import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import UIKit

// MARK: - Catalog Summary Row

struct CatalogSummaryRowView: View {
    let statusCounts: [GameStatus: Int]
    var onStatusTap: ((GameStatus) -> Void)? = nil

    private let order: [GameStatus] = [.playing, .backlog, .wishlist, .completed, .dropped]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(order.indices), id: \.self) { i in
                let status = order[i]
                let count = statusCounts[status] ?? 0
                Button {
                    onStatusTap?(status)
                } label: {
                    VStack(spacing: 2) {
                        Text("\(count)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(status.color)
                            .shadow(color: status.color.opacity(0.35), radius: 0, x: 0, y: 1)
                        Text(status.shortLabel)
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(status.shortLabel), \(count) games")
                .accessibilityHint("Tap to show only \(status.shortLabel) games")
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
    }
}

// MARK: - Filter Menu

struct BacklogFilterMenuView: View {
    @Binding var sortMode: SortMode
    @Binding var filterStatus: GameStatus?
    @Binding var filterPlatform: String?
    @Binding var filterGenre: String?
    let platforms: [String]
    let genres: [String]
    let isFiltered: Bool
    let onClearFilters: () -> Void

    var body: some View {
        Menu {
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
            if !platforms.isEmpty {
                Section("Platform") {
                    Button { filterPlatform = nil } label: {
                        if filterPlatform == nil { Label("All", systemImage: "checkmark") } else { Text("All") }
                    }
                    ForEach(platforms, id: \.self) { p in
                        Button { filterPlatform = p } label: {
                            if filterPlatform == p { Label(p, systemImage: "checkmark") } else { Text(p) }
                        }
                    }
                }
            }
            if !genres.isEmpty {
                Section("Genre") {
                    Button { filterGenre = nil } label: {
                        if filterGenre == nil { Label("All", systemImage: "checkmark") } else { Text("All") }
                    }
                    ForEach(genres, id: \.self) { g in
                        Button { filterGenre = g } label: {
                            if filterGenre == g { Label(g, systemImage: "checkmark") } else { Text(g) }
                        }
                    }
                }
            }
            if isFiltered {
                Section {
                    Button("Clear All Filters", role: .destructive, action: onClearFilters)
                }
            }
        } label: {
            Image(systemName: isFiltered ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
    }
}

// MARK: - Empty States

struct BacklogEmptyStateView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No Games Yet", systemImage: "gamecontroller")
        } description: {
            Text("Add a game to start tracking your backlog.")
        }
        .accessibilityLabel("No games yet. Add a game to start tracking your backlog.")
    }
}

struct BacklogNoResultsStateView: View {
    let searchText: String
    let isFiltered: Bool
    let onClear: () -> Void

    var body: some View {
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
                Button("Clear Filters", action: onClear)
                    .accessibilityLabel("Clear filters")
            }
        }
        .accessibilityLabel("No matches. No games match the current search or filters.")
    }
}

// MARK: - Section Header

struct BacklogSectionHeaderView: View {
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
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
    }
}

// MARK: - Section Block (collapsible section with optional "Add Game" or row content)

struct BacklogSectionBlockView<RowContent: View>: View {
    let status: GameStatus
    let games: [Game]
    let isExpanded: Bool
    let onToggle: () -> Void
    let onAddGame: () -> Void
    @ViewBuilder let rowContent: (Game, Int) -> RowContent

    var body: some View {
        let meta = status.sectionMetadata
        VStack(alignment: .leading, spacing: 0) {
            BacklogSectionHeaderView(
                title: meta.title,
                systemImage: meta.systemImage,
                color: meta.color,
                isExpanded: isExpanded,
                onToggle: onToggle
            )
            if isExpanded {
                if games.isEmpty {
                    Button(action: onAddGame) {
                        Label("Add Game", systemImage: "plus.circle.fill")
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundStyle(meta.color)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add game to \(meta.title)")
                } else {
                    ForEach(Array(games.enumerated()), id: \.element.id) { index, game in
                        rowContent(game, index)
                        if game.id != games.last?.id {
                            Divider()
                                .padding(.leading, 10)
                        }
                    }
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Game Row (catalog list row with cover, title, badges)

struct BacklogGameRowView: View, Equatable {
    let game: Game
    var rank: Int? = nil
    var isMostAnticipated: Bool = false
    var onRateTap: (() -> Void)? = nil
    /// 1-based position within the current group (e.g. first in Backlog = 1).
    var priorityInGroup: Int? = nil

    private let gameId: UUID

    init(game: Game, rank: Int? = nil, isMostAnticipated: Bool = false, onRateTap: (() -> Void)? = nil, priorityInGroup: Int? = nil) {
        self.game = game
        self.gameId = game.id
        self.rank = rank
        self.isMostAnticipated = isMostAnticipated
        self.onRateTap = onRateTap
        self.priorityInGroup = priorityInGroup
    }

    nonisolated static func == (lhs: BacklogGameRowView, rhs: BacklogGameRowView) -> Bool {
        lhs.gameId == rhs.gameId && lhs.rank == rhs.rank && lhs.isMostAnticipated == rhs.isMostAnticipated && lhs.priorityInGroup == rhs.priorityInGroup
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
        HStack(spacing: 8) {
            if let priority = priorityInGroup {
                Text("\(priority)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .frame(minWidth: 20, alignment: .leading)
            }
            if let urlString = game.coverImageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
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
                                    Button { onTap() } label: { personalRatingPill }
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
                        BacklogUnreleasedBadge()
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
        .padding(.vertical, 2)
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

struct BacklogUnreleasedBadge: View {
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

// MARK: - Draggable Row (with drop target highlight)

struct BacklogDraggableRowView<ContextMenuContent: View>: View {
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
            RoundedRectangle(cornerRadius: 10)
                .fill(isTargeted ? Color.accentColor.opacity(0.18) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isTargeted ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 2)
                )
                .frame(maxWidth: .infinity)
            NavigationLink(value: game) {
                BacklogGameRowView(game: game, rank: rank, isMostAnticipated: isMostAnticipated, onRateTap: onRateTap, priorityInGroup: sectionIndex + 1)
                    .equatable()
            }
            .tint(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .animation(.easeOut(duration: 0.1), value: isTargeted)
        .onDrag {
            NSItemProvider(object: game.id.uuidString as NSString)
        }
        .onDrop(of: [.plainText], delegate: BacklogCatalogRowDropDelegate(
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

// MARK: - Drop Delegate

struct BacklogCatalogRowDropDelegate: DropDelegate {
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

// MARK: - Row Drop Modifier (for List single-section drop)

struct BacklogRowDropModifier: ViewModifier {
    let targetStatus: GameStatus?
    let onMoveToCompleted: (() -> Void)?
    let modelContext: ModelContext

    func body(content: Content) -> some View {
        if let targetStatus {
            content.dropDestination(for: String.self) { uuidStrings, _ in
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

// MARK: - Add Details Prompt Sheet

struct BacklogAddDetailsPromptSheet: View {
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
                    Button("Maybe later", action: onLater)
                        .buttonStyle(.bordered)
                    Button("Add details", action: onAdd)
                        .buttonStyle(.borderedProminent)
                }
                .padding(.top, 8)
            }
            .padding(.vertical, 24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onLater)
                }
            }
        }
    }
}
