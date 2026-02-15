import Foundation

/// Six fixed categories for the "Completed by genre" radar chart.
/// Raw genres (e.g. from IGDB) are mapped into these so the chart always has 6 axes.
enum RadarGenreCategories {

    static let count = 6

    /// Display labels for the 6 axes, in order (top axis first, then clockwise).
    static let labels: [String] = [
        "Other",
        "Action & Adventure",
        "Shooter",
        "RPG",
        "Sports & Racing",
        "Horror & Survival",
    ]

    /// SF Symbol names for each axis (same order as labels).
    static let iconNames: [String] = [
        "circle.grid.2x2",        // Other
        "figure.climbing",       // Action & Adventure (person on rope / adventure)
        "scope",                 // Shooter
        "wand.and.stars",        // RPG (wizard / magic)
        "trophy.fill",           // Sports & Racing
        "eye.fill",             // Horror & Survival (creepy / watching)
    ]

    /// Maps a raw genre string (e.g. from IGDB) to a category index 0..<6.
    /// Case-insensitive; genres that don't match the other five categories go to "Other" (index 0).
    static func categoryIndex(for genre: String) -> Int {
        let lower = genre.lowercased()
        // Check action/adventure before shooter so "Action shooter", "Adventure shooter" etc. map to Action & Adventure
        if lower.contains("adventure") || lower.contains("action") || lower.contains("platform")
            || lower.contains("hack and slash") || lower.contains("beat 'em up")
            || lower.contains("point-and-click") || lower.contains("visual novel")
            || lower.contains("puzzle") || lower.contains("arcade") || lower.contains("fighting")
            || lower.contains("indie") || lower.contains("simulator") || lower.contains("music")
            || lower.contains("card") || lower.contains("board") || lower.contains("quiz")
            || lower.contains("pinball") { return 1 }
        // Check horror/survival before shooter so survival-horror (e.g. Resident Evil) isn’t classed as Shooter
        if lower.contains("horror") || lower.contains("survival") { return 5 }
        if lower.contains("shooter") { return 2 }
        if lower.contains("role-playing") || lower.contains("rpg") { return 3 }
        if lower.contains("sport") || lower.contains("racing") { return 4 }
        return 0 // Other: strategy, etc. — anything that doesn't fit above
    }

    /// Returns (label, value) for all 6 categories; values are counts per category.
    static func completedCountsByCategory(from completedGenres: [String]) -> [(label: String, value: Double)] {
        var counts = [Double](repeating: 0, count: count)
        for g in completedGenres {
            let idx = categoryIndex(for: g)
            counts[idx] += 1
        }
        return zip(labels, counts).map { (label: $0.0, value: $0.1) }
    }
}
