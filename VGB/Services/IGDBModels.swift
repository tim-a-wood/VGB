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

    /// Primary genre for display. Uses GenreResolver to score name + summary so we don't
    /// default to Adventure when IGDB returns inconsistent genre lists. Themes (Horror/Survival)
    /// still override; otherwise the resolver picks the best-matching genre from text and DB.
    var primaryGenre: String? {
        let genreNames = genres?.compactMap(\.name).filter { !$0.isEmpty } ?? []
        let themeNames = themes?.compactMap { t in t.name ?? t.slug }.compactMap { $0 }.filter { !$0.isEmpty } ?? []
        return GenreResolver.resolve(
            name: name,
            summary: summary,
            genreNames: genreNames,
            themeNames: themeNames
        )
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
