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
    let involvedCompanies: [IGDBInvolvedCompany]?
    let firstReleaseDate: Int? // Unix timestamp
    let totalRating: Double?   // IGDB aggregated critic + user rating (0–100)
    let summary: String?

    enum CodingKeys: String, CodingKey {
        case id, name, cover, platforms, genres, summary
        case involvedCompanies = "involved_companies"
        case firstReleaseDate = "first_release_date"
        case totalRating = "total_rating"
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

    /// Convenience: primary genre name.
    var primaryGenre: String? {
        genres?.first?.name
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

struct IGDBInvolvedCompany: Decodable, Sendable {
    let id: Int?
    let company: IGDBCompany?
    let developer: Bool?
}

struct IGDBCompany: Decodable, Sendable {
    let id: Int?
    let name: String?
}
