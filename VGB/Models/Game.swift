import Foundation
import SwiftData

/// Core domain model for a game in the user's backlog.
///
/// Fields are grouped by ownership:
/// - **User-owned**: editable by the user, never overwritten by metadata sync.
/// - **Provider-sourced**: fetched from an external API, overwritten on refresh.
/// - **System-managed**: set automatically by the app.
@Model
final class Game {

    // MARK: - User-owned

    /// Lifecycle status (Wishlist, Backlog, Playing, Completed, Dropped).
    var statusRaw: String = GameStatus.backlog.rawValue

    /// Drag-and-drop priority rank. Lower value = higher priority.
    var priorityPosition: Int = 0

    /// User's own estimate of how long the game takes to complete.
    var estimatedHours: Double?

    /// Free-text notes from the user.
    var personalNotes: String = ""

    /// User's personal rating (0–100 scale).
    var personalRating: Int?

    // MARK: - Provider-sourced (read-only, refreshable)

    /// Game title from the metadata provider.
    var title: String = ""

    /// Platform name (e.g. "PS5", "PC", "Switch").
    var platform: String = ""

    /// Official release date.
    var releaseDate: Date?

    /// URL string for the game's cover art.
    var coverImageURL: String?

    /// IGDB aggregated critic + user rating (0–100).
    var igdbRating: Int?

    /// Primary genre.
    var genre: String?

    /// Developer studio name.
    var developer: String?

    // MARK: - System-managed

    /// Local unique identifier.
    @Attribute(.unique) var id: UUID = UUID()

    /// Identifier from the metadata provider (links local game to API).
    var externalId: String?

    /// When provider-sourced fields were last refreshed.
    var lastSyncedAt: Date?

    /// When the user added this game.
    var createdAt: Date = Date()

    /// Last modification timestamp (user or sync).
    var updatedAt: Date = Date()

    // MARK: - Computed

    /// Typed accessor for status.
    var status: GameStatus {
        get { GameStatus(rawValue: statusRaw) ?? .backlog }
        set { statusRaw = newValue.rawValue }
    }

    /// Whether this game has a release date in the future.
    var isUnreleased: Bool {
        guard let date = releaseDate else { return false }
        return date > Date()
    }

    /// Platform string for display (e.g. "PC" instead of "PC (Microsoft Windows)").
    var displayPlatform: String {
        Self.displayPlatform(from: platform)
    }

    /// Normalizes a raw platform string for display (e.g. "PC" not "PC (Microsoft Windows)", "PS5" not "PlayStation 5").
    static func displayPlatform(from raw: String) -> String {
        var s = raw
            .replacingOccurrences(of: " (Microsoft Windows)", with: "")
        for (full, short) in [
            ("PlayStation 5", "PS5"),
            ("PlayStation 4", "PS4"),
            ("PlayStation 3", "PS3"),
            ("PlayStation 2", "PS2"),
            ("PlayStation 1", "PS1"),
        ] {
            s = s.replacingOccurrences(of: full, with: short)
        }
        return s.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Init

    init(
        title: String,
        platform: String = "",
        status: GameStatus = .backlog,
        priorityPosition: Int = 0
    ) {
        self.title = title
        self.platform = platform
        self.statusRaw = status.rawValue
        self.priorityPosition = priorityPosition
    }
}
