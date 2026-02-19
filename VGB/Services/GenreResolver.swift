import Foundation

/// Resolves a single display genre from IGDB (or similar) data.
///
/// **Design:**
/// 1. **Theme override** — Horror/Survival theme → always "Horror".
/// 2. **Strong phrase overrides** — A small set of high-confidence phrases in name+summary
///    (e.g. "survival horror", "souls-like", "turn-based strategy", "first-person shooter")
///    can override the DB. No generic keyword scoring.
/// 3. **DB-first** — Map IGDB genre names to our canonical set, then pick one by a fixed
///    priority (so we prefer Shooter over Action over Adventure when multiple are present).
/// 4. **RPG + Action** — If the DB gives both RPG and Action, we emit "Action RPG".
/// 5. **No genres** — If there are no IGDB genres and no phrase matched, return "Other" when
///    we have name/summary, else nil.
///
/// This avoids scoring free text for vague words ("tactics", "campaign") that incorrectly
/// push action games into Strategy.
enum GenreResolver {

    /// Canonical genre labels we emit (aligned with RadarGenreCategories).
    static let knownGenres: [String] = [
        "Horror", "Strategy", "RPG", "Action RPG", "Roguelike", "Shooter", "Action", "Adventure",
        "Fighting", "Racing", "Sports", "Simulation", "Puzzle", "Other",
    ]

    /// Priority order: when IGDB returns multiple genres, we pick the one that appears
    /// earliest here (most specific / most informative first).
    private static let priorityOrder: [String] = [
        "Horror", "Shooter", "RPG", "Action RPG", "Roguelike", "Strategy", "Fighting",
        "Racing", "Sports", "Simulation", "Puzzle", "Action", "Adventure", "Other",
    ]

    static func resolve(
        name: String?,
        summary: String?,
        genreNames: [String],
        themeNames: [String]
    ) -> String? {
        let text = combinedText(name: name, summary: summary)
        let themes = themeNames.map { $0.lowercased() }

        // 1) Theme override
        if themes.contains(where: { $0.contains("horror") || $0.contains("survival") }) {
            return "Horror"
        }

        // 2) Strong phrase overrides (high confidence only; first match wins)
        if let fromPhrase = resolveFromPhrases(text) {
            return fromPhrase
        }

        // 3) DB-first: map IGDB genres to canonical, then pick by priority
        let canonicalSet = Set(
            genreNames.compactMap { igdbNameToCanonical($0) }
        )

        if canonicalSet.isEmpty {
            return text.isEmpty ? nil : "Other"
        }

        // If both RPG and Action are present, treat as Action RPG
        if canonicalSet.contains("RPG") && canonicalSet.contains("Action") {
            return "Action RPG"
        }

        // Pick first in priority order that appears in the set
        for genre in priorityOrder {
            if canonicalSet.contains(genre) { return genre }
        }

        return "Other"
    }

    // MARK: - Strong phrase overrides (no generic scoring)

    /// First matching phrase wins. Order matters: more specific / rarer phrases first.
    private static func resolveFromPhrases(_ text: String) -> String? {
        let lower = text.lowercased()
        guard !lower.isEmpty else { return nil }

        // Horror
        if lower.contains("survival horror") { return "Horror" }

        // Strategy (only explicit strategy-game phrases)
        if lower.contains("turn-based strategy") || lower.contains("real-time strategy")
            || lower.contains("strategy game") || lower.contains(" 4x ")
            || lower.range(of: #"\brts\b"#, options: .regularExpression) != nil
            || lower.contains("real-time strategy (rts)") { return "Strategy" }

        // Shooter (explicit shooter phrases; avoid "60fps" by requiring word-boundary fps)
        if lower.contains("first-person shooter") || lower.contains("first person shooter")
            || lower.contains("battle royale") || lower.contains("tactical shooter")
            || lower.range(of: #"\bfps\b"#, options: .regularExpression) != nil { return "Shooter" }

        // Action RPG / RPG
        if lower.contains("souls-like") || lower.contains("soulslike") { return "Action RPG" }
        if lower.contains("open world rpg") || lower.contains("open world role-playing") { return "RPG" }

        // Roguelike
        if lower.contains("roguelike") || lower.contains("rogue-like") { return "Roguelike" }

        return nil
    }

    // MARK: - IGDB name → canonical mapping

    private static func igdbNameToCanonical(_ name: String) -> String? {
        let n = name.trimmingCharacters(in: .whitespaces).lowercased()
        guard !n.isEmpty else { return nil }
        return igdbToCanonicalMap[n] ?? igdbToCanonicalByPrefix(n)
    }

    /// Exact and normalized IGDB genre names → our canonical label.
    private static let igdbToCanonicalMap: [String: String] = [
        "action": "Action",
        "adventure": "Adventure",
        "shooter": "Shooter",
        "role-playing (rpg)": "RPG",
        "rpg": "RPG",
        "role-playing": "RPG",
        "action rpg": "Action RPG",
        "action role-playing": "Action RPG",
        "jrpg": "RPG",
        "strategy": "Strategy",
        "real-time strategy (rts)": "Strategy",
        "rts": "Strategy",
        "real-time strategy": "Strategy",
        "turn-based strategy": "Strategy",
        "turn-based": "Strategy",
        "fighting": "Fighting",
        "racing": "Racing",
        "sport": "Sports",
        "sports": "Sports",
        "simulation": "Simulation",
        "puzzle": "Puzzle",
        "roguelike": "Roguelike",
        "rogue-like": "Roguelike",
        "hack and slash": "Action",
        "platformer": "Action",
        "platform": "Action",
        "beat 'em up": "Action",
        "tactical": "Strategy",
        "moba": "Strategy",
        "indie": "Other",
        "point-and-click": "Adventure",
        "visual novel": "Adventure",
        "music": "Other",
        "pinball": "Other",
        "card": "Other",
        "board": "Other",
        "quiz": "Other",
    ]

    /// Fallback: match by prefix so "Role-playing (RPG)" and similar variants map correctly.
    private static func igdbToCanonicalByPrefix(_ lower: String) -> String? {
        let prefixes: [(String, String)] = [
            ("role-playing", "RPG"),
            ("action", "Action"),
            ("adventure", "Adventure"),
            ("shooter", "Shooter"),
            ("strategy", "Strategy"),
            ("real-time strategy", "Strategy"),
            ("turn-based strategy", "Strategy"),
            ("turn-based", "Strategy"),
            ("fighting", "Fighting"),
            ("racing", "Racing"),
            ("sport", "Sports"),
            ("simulation", "Simulation"),
            ("puzzle", "Puzzle"),
            ("roguelike", "Roguelike"),
            ("rogue-like", "Roguelike"),
            ("hack and slash", "Action"),
            ("platformer", "Action"),
            ("platform", "Action"),
        ]
        for (prefix, canonical) in prefixes {
            if lower.hasPrefix(prefix) { return canonical }
        }
        return nil
    }

    private static func combinedText(name: String?, summary: String?) -> String {
        let a = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let b = (summary ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(a) \(b)".lowercased()
    }
}
