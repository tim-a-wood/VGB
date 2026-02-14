import Foundation

/// Lifecycle status of a game in the user's backlog.
enum GameStatus: String, Codable, CaseIterable, Identifiable {
    case backlog   = "Backlog"
    case playing   = "Playing"
    case completed = "Completed"
    case dropped   = "Dropped"

    var id: String { rawValue }
}
