import Foundation

/// Raw response models for IGDB API JSON.
/// These are separate from the SwiftData `Game` model — we map from these to `Game`.

// MARK: - Game Search Result

struct IGDBGame: Decodable, Sendable {
    let id: Int
    let name: String?
    let cover: IGDBCover?
    let platforms: [IGDBPlatform]?
    let genres: [IGDBGenre]?
    let themes: [IGDBTheme]?
    let involvedCompanies: [IGDBInvolvedCompany]?
    let firstReleaseDate: Int? // Unix timestamp
    let totalRating: Double?   // IGDB aggregated critic + user rating (0–100)
    let summary: String?

    enum CodingKeys: String, CodingKey {
        case id, name, cover, platforms, genres, themes, summary
        case involvedCompanies = "involved_companies"
        case firstReleaseDate = "first_release_date"
        case totalRating = "total_rating"
    }

    /// Memberwise init for tests and manual construction.
    init(
        id: Int,
        name: String?,
        cover: IGDBCover?,
        platforms: [IGDBPlatform]?,
        genres: [IGDBGenre]?,
        themes: [IGDBTheme]?,
        involvedCompanies: [IGDBInvolvedCompany]?,
        firstReleaseDate: Int?,
        totalRating: Double?,
        summary: String?
    ) {
        self.id = id
        self.name = name
        self.cover = cover
        self.platforms = platforms
        self.genres = genres
        self.themes = themes
        self.involvedCompanies = involvedCompanies
        self.firstReleaseDate = firstReleaseDate
        self.totalRating = totalRating
        self.summary = summary
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        cover = try c.decodeIfPresent(IGDBCover.self, forKey: .cover)
        platforms = try c.decodeIfPresent([IGDBPlatform].self, forKey: .platforms)
        genres = try c.decodeIfPresent([IGDBGenre].self, forKey: .genres)
        involvedCompanies = try c.decodeIfPresent([IGDBInvolvedCompany].self, forKey: .involvedCompanies)
        firstReleaseDate = try c.decodeIfPresent(Int.self, forKey: .firstReleaseDate)
        totalRating = try c.decodeIfPresent(Double.self, forKey: .totalRating)
        summary = try c.decodeIfPresent(String.self, forKey: .summary)

        // Themes: IGDB may return expanded objects [{id,name,slug}] or IDs only [19,42].
        // When IDs only, we synthesize themes from known horror/survival IDs.
        if let expanded = try? c.decode([IGDBTheme].self, forKey: .themes) {
            themes = expanded
        } else if let ids = try? c.decode([Int].self, forKey: .themes) {
            themes = ids.map { themeId in
                IGDBTheme(id: themeId, name: Self.themeName(forId: themeId), slug: Self.themeSlug(forId: themeId))
            }
        } else {
            themes = nil
        }
    }

    private static func themeName(forId id: Int) -> String? {
        switch id {
        case 19: return "Horror"
        case 42: return "Survival"
        default: return nil
        }
    }

    private static func themeSlug(forId id: Int) -> String? {
        switch id {
        case 19: return "horror"
        case 42: return "survival"
        default: return nil
        }
    }

    /// Convenience: release date as `Date`.
    var releaseDate: Date? {
        guard let ts = firstReleaseDate else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(ts))
    }

    /// Convenience: primary developer name.
    var developerName: String? {
        involvedCompanies?
            .first(where: { $0.developer == true })?
            .company?.name
    }

    /// Convenience: primary genre name. When IGDB returns multiple genres, we pick one by precedence.
    /// If themes hint at Horror (e.g. "Horror", "Survival"), we mark the genre as Horror.
    /// Fallback: if summary mentions "horror" or "survival horror", classify as Horror (IGDB metadata can be incomplete).
    var primaryGenre: String? {
        if themesHintAtHorror || summaryHintsAtHorror {
            return "Horror"
        }
        guard let genres = genres, !genres.isEmpty else { return nil }
        let names = genres.compactMap(\.name).filter { !$0.isEmpty }
        return Self.preferredGenre(from: names)
    }

    /// True if any theme name or slug hints at the game being horror (e.g. "Horror", "Survival").
    private var themesHintAtHorror: Bool {
        guard let themes = themes else { return false }
        for t in themes {
            let name = (t.name ?? "").lowercased()
            let slug = (t.slug ?? "").lowercased()
            if name.contains("horror") || name.contains("survival") || slug == "horror" || slug == "survival" {
                return true
            }
        }
        return false
    }

    /// True if the summary text mentions horror (e.g. "survival horror", "horror game"). Fallback when themes are missing.
    private var summaryHintsAtHorror: Bool {
        guard let s = summary, !s.isEmpty else { return false }
        let lower = s.lowercased()
        return lower.contains("horror") || lower.contains("survival horror")
    }

    /// Picks a single genre for display when multiple exist; Adventure/Action take precedence over Shooter (and Horror/Survival over Shooter).
    static func preferredGenre(from names: [String]) -> String? {
        guard !names.isEmpty else { return nil }
        return names.min(by: { genrePriority($0) < genrePriority($1) })
    }

    private static func genrePriority(_ genre: String) -> Int {
        let lower = genre.lowercased()
        if lower.contains("adventure") || lower.contains("action") { return 0 }
        if lower.contains("horror") || lower.contains("survival") { return 1 }
        if lower.contains("shooter") { return 2 }
        if lower.contains("role-playing") || lower.contains("rpg") { return 3 }
        if lower.contains("sport") || lower.contains("racing") { return 4 }
        return 5
    }

    /// Convenience: primary platform name.
    var primaryPlatform: String? {
        platforms?.first?.name
    }

    /// Convenience: all platform names joined.
    var platformNames: [String] {
        platforms?.compactMap(\.name) ?? []
    }

    /// Convenience: full cover image URL (bigger size).
    var coverURL: String? {
        guard let hash = cover?.imageId else { return nil }
        return "https://images.igdb.com/igdb/image/upload/t_cover_big/\(hash).jpg"
    }

    /// Convenience: thumbnail cover URL (smaller).
    var thumbnailURL: String? {
        guard let hash = cover?.imageId else { return nil }
        return "https://images.igdb.com/igdb/image/upload/t_thumb/\(hash).jpg"
    }
}

// MARK: - Nested Types

struct IGDBCover: Decodable, Sendable {
    let id: Int?
    let imageId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case imageId = "image_id"
    }
}

struct IGDBPlatform: Decodable, Sendable {
    let id: Int?
    let name: String?
}

struct IGDBGenre: Decodable, Sendable {
    let id: Int?
    let name: String?
}

struct IGDBTheme: Decodable, Sendable {
    let id: Int?
    let name: String?
    let slug: String?
}

struct IGDBInvolvedCompany: Decodable, Sendable {
    let id: Int?
    let company: IGDBCompany?
    let developer: Bool?
}

struct IGDBCompany: Decodable, Sendable {
    let id: Int?
    let name: String?
}
