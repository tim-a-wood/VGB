import SwiftUI

/// Rounded design for a friendlier look. Use with explicit type: .font(Font.vgbBody)
private let design: Font.Design = .rounded

/// Central type scale for the app. Use .font(Font.vgbBody) etc. so fonts stay consistent and respect Dynamic Type.
extension Font {

    /// App name / hero (e.g. Checkpoint header).
    static let vgbLargeTitle = Font.system(.title, weight: .bold, design: design)

    /// Screen or card title (e.g. "Game Completed!", onboarding page title).
    static let vgbTitle = Font.system(.title2, weight: .bold, design: design)

    /// Card or list header (e.g. rankings row title).
    static let vgbCardTitle = Font.system(.title3, weight: .semibold, design: design)

    /// Section headers and emphasized row context (e.g. "Now Playing", "Gamer Profile").
    static let vgbSectionTitle = Font.system(.subheadline, weight: .semibold, design: design)

    /// Section tile title (e.g. "Completed %", "Critic score" in stats).
    static let vgbSectionTitleBold = Font.system(.subheadline, weight: .bold, design: design)

    /// Primary row text (e.g. game title in catalog row).
    static let vgbRowTitle = Font.system(.headline, weight: .regular, design: design)

    /// Body text and descriptions.
    static let vgbBody = Font.system(.body, design: design)

    /// Labels, metadata, secondary info (e.g. platform, "Playing", "Next").
    static let vgbSecondary = Font.system(.caption, design: design)

    /// Fine print, hints, tertiary labels (e.g. "Unrated", stat footnotes).
    static let vgbTertiary = Font.system(.caption2, design: design)

    /// Emphasized caption (e.g. catalog summary count, badge text).
    static let vgbSecondaryBold = Font.system(.caption, weight: .semibold, design: design)

    /// Tertiary with medium weight for labels.
    static let vgbTertiaryMedium = Font.system(.caption2, weight: .medium, design: design)

    /// Tertiary with semibold (e.g. badges like "Most Anticipated").
    static let vgbTertiarySemibold = Font.system(.caption2, weight: .semibold, design: design)
}
