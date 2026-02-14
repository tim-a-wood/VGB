import Foundation

/// Six fixed categories for the "Completed by genre" radar chart.
/// Raw genres (e.g. from IGDB) are mapped into these so the chart always has 6 axes.
enum RadarGenreCategories {

    static let count = 6

    /// Display labels for the 6 axes, in order (top axis first, then clockwise).
    static let labels: [String] = [
        "Strategy",
        "Action & Adventure",
        "Shooter",
        "RPG",
        "Sports & Racing",
        "Horror & Survival",
    ]

    /// Maps a raw genre string (e.g. from IGDB) to a category index 0..<6.
    /// Case-insensitive; unknown genres go to "Action & Adventure" (index 1).
    static func categoryIndex(for genre: String) -> Int {
        let lower = genre.lowercased()
        if lower.contains("strategy") || lower.contains("tactical") || lower.contains("moba")
            || lower.contains("rts") || lower.contains("tbs") { return 0 }
        if lower.contains("adventure") || lower.contains("action") || lower.contains("platform")
            || lower.contains("hack and slash") || lower.contains("beat 'em up")
            || lower.contains("point-and-click") || lower.contains("visual novel")
            || lower.contains("puzzle") || lower.contains("arcade") || lower.contains("fighting")
            || lower.contains("indie") || lower.contains("simulator") || lower.contains("music")
            || lower.contains("card") || lower.contains("board") || lower.contains("quiz")
            || lower.contains("pinball") { return 1 }
        if lower.contains("shooter") { return 2 }
        if lower.contains("role-playing") || lower.contains("rpg") { return 3 }
        if lower.contains("sport") || lower.contains("racing") { return 4 }
        if lower.contains("horror") || lower.contains("survival") { return 5 }
        return 1 // Catch-all: Action & Adventure
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
