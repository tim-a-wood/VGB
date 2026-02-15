import UIKit

/// Lightweight haptic feedback for key user actions.
enum Haptic {
    /// Success (e.g. game added, marked completed).
    case success
    /// Warning (e.g. destructive action).
    case warning
    /// Light tap (e.g. navigation / get started).
    case light

    func play() {
        switch self {
        case .success:
            let g = UINotificationFeedbackGenerator()
            g.notificationOccurred(.success)
        case .warning:
            let g = UINotificationFeedbackGenerator()
            g.notificationOccurred(.warning)
        case .light:
            let g = UIImpactFeedbackGenerator(style: .light)
            g.impactOccurred()
        }
    }
}
