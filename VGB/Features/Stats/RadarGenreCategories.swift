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

    /// Maps a raw genre string (e.g. from IGDB or GenreResolver) to a category index 0..<6.
    /// Uses explicit lookup first, then keyword fallback (RPG before generic action). Case-insensitive.
    static func categoryIndex(for genre: String) -> Int {
        let trimmed = genre.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return 0 }
        let lower = trimmed.lowercased()
        // 1) Explicit lookup first
        if let idx = knownGenreToIndex[lower] { return idx }
        for (key, idx) in knownGenreToIndex {
            if lower == key || lower.hasPrefix(key) || key.hasPrefix(lower) { return idx }
        }
        // 2) Keyword fallback — RPG before generic "action" so "Action RPG" → RPG
        if lower.contains("role-playing") || lower.contains("rpg") || lower.contains("action rpg") { return 3 }
        if lower.contains("horror") || lower.contains("survival") { return 5 }
        if lower.contains("shooter") { return 2 }
        if lower.contains("sport") || lower.contains("racing") { return 4 }
        if lower.contains("adventure") || lower.contains("action") || lower.contains("platform")
            || lower.contains("hack and slash") || lower.contains("beat 'em up")
            || lower.contains("point-and-click") || lower.contains("visual novel")
            || lower.contains("puzzle") || lower.contains("arcade") || lower.contains("fighting")
            || lower.contains("indie") || lower.contains("simulator") || lower.contains("music")
            || lower.contains("pinball") || lower.contains("roguelike") { return 1 }
        return 0 // Other: strategy, tactical, etc. — anything that doesn't fit above
    }

    /// Lookup: normalized genre string → radar index (0=Other, 1=Action&Adventure, 2=Shooter, 3=RPG, 4=Sports&Racing, 5=Horror&Survival)
    private static let knownGenreToIndex: [String: Int] = [
        "strategy": 0, "tactical": 0, "real-time strategy": 0, "turn-based strategy": 0,
        "rts": 0, "4x": 0, "moba": 0, "simulation": 0, "other": 0,
        "action": 1, "adventure": 1, "action-adventure": 1, "action adventure": 1,
        "platformer": 1, "platform": 1, "fighting": 1, "puzzle": 1, "arcade": 1,
        "roguelike": 1, "rogue-like": 1, "indie": 1, "visual novel": 1,
        "point-and-click": 1, "hack and slash": 1, "music": 1, "card": 1, "board": 1, "quiz": 1, "pinball": 1,
        "shooter": 2, "first-person shooter": 2, "fps": 2, "third-person shooter": 2, "tps": 2, "battle royale": 2,
        "rpg": 3, "role-playing": 3, "action rpg": 3, "jrpg": 3, "massively multiplayer": 3, "mmorpg": 3,
        "sports": 4, "sport": 4, "racing": 4, "driving": 4, "sports game": 4, "racing game": 4,
        "horror": 5, "survival": 5, "survival horror": 5,
    ]

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
