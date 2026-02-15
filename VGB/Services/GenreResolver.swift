import Foundation

/// Resolves a single display genre from inconsistent DB metadata by scoring the game name and
/// description (summary) against keyword sets. Prefer this over trusting IGDB genre order, which
/// often labels everything as Adventure/Action.
enum GenreResolver {

    /// Canonical genre labels we emit (aligned with RadarGenreCategories where possible).
    /// Strategy before RPG so 4x/turn-based strategy games don’t get misclassified as RPG.
    static let knownGenres: [String] = [
        "Horror", "Strategy", "RPG", "Action RPG", "Roguelike", "Shooter", "Action", "Adventure",
        "Fighting", "Racing", "Sports", "Simulation", "Puzzle", "Other",
    ]

    /// Resolve primary genre from IGDB (or similar) game data using name + summary.
    /// Themes (e.g. Horror, Survival) override when present; otherwise we score the combined
    /// text against keyword sets and pick the highest-scoring genre. IGDB genres are used only
    /// as candidates when provided; if the text scores zero for all, we fall back to the first
    /// DB genre or "Other".
    static func resolve(
        name: String?,
        summary: String?,
        genreNames: [String],
        themeNames: [String]
    ) -> String? {
        let text = combinedSearchableText(name: name, summary: summary)
        let themes = themeNames.map { $0.lowercased() }

        // Strong override: themes explicitly say Horror/Survival → Horror
        if themes.contains(where: { $0.contains("horror") || $0.contains("survival") }) {
            return "Horror"
        }

        // Score the combined text against all known genres so description can override DB (e.g. "survival horror" → Horror).
        var bestGenre: String?
        var bestScore: Double = -1
        for genre in knownGenres {
            let s = score(text: text, for: genre)
            if s > bestScore {
                bestScore = s
                bestGenre = genre
            }
        }

        // No signal from text: use first DB genre if provided
        if bestScore <= 0 {
            if let first = genreNames.first, !first.isEmpty {
                return normalizeGenreName(first)
            }
            // No DB genres and no theme override: return nil so callers treat as unknown (matches old behavior)
            if genreNames.isEmpty { return nil }
            let hasInput = !((name ?? "").trimmingCharacters(in: .whitespaces).isEmpty && (summary ?? "").trimmingCharacters(in: .whitespaces).isEmpty)
            return hasInput ? "Other" : nil
        }
        return bestGenre
    }

    // MARK: - Private

    private static func combinedSearchableText(name: String?, summary: String?) -> String {
        let a = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let b = (summary ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(a) \(b)".lowercased()
    }

    private static func normalizeGenreName(_ s: String) -> String {
        let lower = s.trimmingCharacters(in: .whitespaces).lowercased()
        if lower.contains("role-playing") || lower == "rpg" { return "RPG" }
        if lower.contains("action") && lower.contains("rpg") { return "Action RPG" }
        if lower.contains("action") { return "Action" }
        if lower.contains("adventure") { return "Adventure" }
        if lower.contains("shooter") { return "Shooter" }
        if lower.contains("horror") { return "Horror" }
        if lower.contains("survival") { return "Horror" }
        if lower.contains("roguelike") || lower.contains("rogue-like") { return "Roguelike" }
        if lower.contains("fighting") { return "Fighting" }
        if lower.contains("racing") { return "Racing" }
        if lower.contains("sport") { return "Sports" }
        if lower.contains("strateg") { return "Strategy" }
        if lower.contains("simulat") { return "Simulation" }
        if lower.contains("puzzle") { return "Puzzle" }
        return s.trimmingCharacters(in: .whitespaces)
    }

    /// (keyword, weight). Higher weight = stronger signal. Avoids generic words (e.g. "level", "experience") that match shooters too.
    private static func weightedKeywords(for genre: String) -> [(String, Double)] {
        let g = genre.lowercased()
        if g == "horror" {
            return [
                ("survival horror", 2.5), ("horror", 2), ("zombie", 1.5), ("undead", 1.5),
                ("supernatural", 1), ("terror", 1), ("haunted", 1), ("psychological horror", 1.5), ("scary", 0.5),
            ]
        }
        if g == "rpg" || g == "action rpg" {
            return [
                ("role-playing", 2.5), ("rpg", 2.5), ("open world rpg", 2),
                ("quest", 1.5), ("dungeon", 1.5), ("magic", 1.5), ("spell", 1), ("skill tree", 1.5),
                ("level up", 1.5), ("xp", 1), ("character progression", 1.5), ("souls-like", 1.5), ("soulslike", 1.5),
                ("jrpg", 1.5), ("turn-based", 1), ("inventory", 1), ("dialogue choices", 1),
                ("party", 0.5), ("class", 0.5), ("stats", 0.5), ("loot", 0.3),
            ]
        }
        if g == "roguelike" {
            return [
                ("roguelike", 2), ("rogue-like", 2), ("permadeath", 1.5), ("procedural", 1),
                ("run-based", 1), ("each run", 1),
            ]
        }
        if g == "shooter" {
            return [
                ("first-person shooter", 2.5), ("fps", 2), ("shooter", 2), ("multiplayer shooter", 2),
                ("military", 1.5), ("soldier", 1.5), ("battlefield", 1.5), ("warfare", 1), ("infantry", 1),
                ("tactical shooter", 1.5), ("battle royale", 1.5), ("gun", 1), ("weapon", 0.8),
                ("first-person", 1), ("first person", 1), ("squad", 0.8), ("war", 0.5), ("combat", 0.3),
            ]
        }
        if g == "action" {
            return [
                ("hack and slash", 1.5), ("beat 'em up", 1.5), ("platformer", 1.5), ("melee", 1),
                ("boss fight", 1), ("real-time combat", 1), ("action game", 0.8), ("action-adventure", 0.5),
            ]
        }
        if g == "adventure" {
            return [
                ("point-and-click", 1.5), ("visual novel", 1.5), ("puzzle-adventure", 1.5),
                ("story-driven", 1), ("narrative", 0.8), ("adventure game", 1),
                ("explore", 0.4), ("exploration", 0.4), ("adventure", 0.5),
            ]
        }
        if g == "fighting" {
            return [("fighting game", 2), ("fighter", 1.5), ("versus", 1), ("arena fighter", 1), ("combo", 0.5)]
        }
        if g == "racing" {
            return [("racing game", 1.5), ("racing", 1.5), ("driving", 1), ("motorsport", 1), ("vehicle", 0.5)]
        }
        if g == "sports" {
            return [("sports game", 1.5), ("football", 1), ("soccer", 1), ("basketball", 1), ("fifa", 1.5), ("madden", 1.5)]
        }
        if g == "strategy" {
            return [
                ("strategy game", 2.5), ("strategy", 2), ("real-time strategy", 2), ("turn-based strategy", 2),
                ("4x", 2), ("rts", 2), ("civilization", 1.5), ("civ ", 1.5), ("heroes of might", 1.5), ("might and magic", 1.5),
                ("tactics", 1.5), ("tactical game", 1.5), ("empire", 1), ("conquer", 1), ("warlord", 1),
                ("army", 1), ("units", 0.8), ("factions", 0.8), ("hex", 0.8), ("resource management", 0.8),
                ("build orders", 1), ("campaign map", 1),
            ]
        }
        if g == "simulation" {
            return [("simulation", 1.5), ("city builder", 1.5), ("management", 1), ("life sim", 1)]
        }
        if g == "puzzle" {
            return [("puzzle game", 1.5), ("puzzle", 1), ("match", 0.5)]
        }
        return []
    }

    private static func score(text: String, for genre: String) -> Double {
        var total: Double = 0
        for (keyword, weight) in weightedKeywords(for: genre) {
            if text.contains(keyword) {
                total += weight
            }
        }
        return total
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
