import Foundation
import SwiftUI

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

    /// Short label for compact UI (catalog summary row).
    var shortLabel: String { rawValue }

    /// Section title for catalog view (e.g. "Now Playing" vs "Playing").
    var sectionTitle: String {
        switch self {
        case .playing: return "Now Playing"
        case .backlog: return "Backlog"
        case .wishlist: return "Wishlist"
        case .completed: return "Completed"
        case .dropped: return "Dropped"
        }
    }

    /// SF Symbol for section headers and context menus.
    var sectionIcon: String {
        switch self {
        case .playing: return "play.fill"
        case .backlog: return "list.bullet"
        case .wishlist: return "heart.fill"
        case .completed: return "checkmark.circle.fill"
        case .dropped: return "xmark.circle.fill"
        }
    }

    /// Statuses available for selection. Unreleased games can only be Wishlist.
    static func availableStatuses(for isUnreleased: Bool) -> [GameStatus] {
        isUnreleased ? [.wishlist] : Array(allCases)
    }
}
