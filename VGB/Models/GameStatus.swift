import Foundation

/// Lifecycle status of a game in the user's backlog.
///
/// Lifecycle: Wishlist → Backlog → Playing → Completed / Dropped
enum GameStatus: String, Codable, CaseIterable, Identifiable {
    case wishlist  = "Wishlist"
    case backlog   = "Backlog"
    case playing   = "Playing"
    case completed = "Completed"
    case dropped   = "Dropped"

    var id: String { rawValue }
}
