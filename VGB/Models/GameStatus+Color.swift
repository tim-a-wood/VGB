import SwiftUI

extension GameStatus {
    /// Color used for badges and charts (status donut, bar charts).
    var color: Color {
        switch self {
        case .wishlist:  .purple
        case .backlog:   .gray
        case .playing:   .blue
        case .completed: .green
        case .dropped:   .orange
        }
    }
}
