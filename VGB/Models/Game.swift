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

    /// Whether this game is unreleased: no release date (unknown) or date in the future.
    var isUnreleased: Bool {
        guard let date = releaseDate else { return true }
        return date > Date()
    }

    /// Platform string for display (e.g. "PC" instead of "PC (Microsoft Windows)").
    var displayPlatform: String {
        Self.displayPlatform(from: platform)
    }

    /// Splits a combined platform string (e.g. "PS5, PC" from IGDB) into individual platforms.
    static func platformComponents(_ platformString: String) -> [String] {
        let trimmed = platformString.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        return trimmed
            .components(separatedBy: CharacterSet(charactersIn: ",|/"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// Platform names (lowercased) that are shown as a single "PC" to reduce clutter.
    private static let pcTypePlatformNames: Set<String> = [
        "pc", "microsoft windows", "windows", "mac", "macos", "os mac", "linux", "steam os", "steamos",
    ]

    /// Normalizes a raw platform string for display (e.g. "PC" not "PC (Microsoft Windows)", "PS5" not "PlayStation 5").
    /// PC, Mac, Linux, Windows (and variants) are all shown as "PC".
    static func displayPlatform(from raw: String) -> String {
        let components = platformComponents(raw)
        let normalized = components.map { normalizePlatformComponent($0) }
        var seen = Set<String>()
        let deduped = normalized.filter { seen.insert($0).inserted }
        return deduped.joined(separator: ", ")
    }

    /// Normalizes one platform component and collapses PC-type platforms to "PC".
    private static func normalizePlatformComponent(_ raw: String) -> String {
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
        s = s.trimmingCharacters(in: .whitespaces)
        if pcTypePlatformNames.contains(s.lowercased()) {
            return "PC"
        }
        return s
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

extension Game: Identifiable {}
