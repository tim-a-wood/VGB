import Foundation

/// Errors that can occur during IGDB API operations.
enum IGDBError: LocalizedError {
    case authFailed
    case requestFailed(statusCode: Int)
    case decodingFailed(underlying: Error)
    case noResults
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .authFailed:
            return "Failed to authenticate with Twitch. Check your API credentials."
        case .requestFailed(let code):
            return "IGDB request failed (HTTP \(code))."
        case .decodingFailed:
            return "Failed to parse game data from IGDB."
        case .noResults:
            return "No games found."
        case .networkUnavailable:
            return "No internet connection. Your local data is still available."
        }
    }
}
