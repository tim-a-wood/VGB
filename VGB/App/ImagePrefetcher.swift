import Foundation
import SwiftData

/// Prefetches image URLs into the shared URLCache so AsyncImage loads instantly.
enum ImagePrefetcher {

    /// Maximum number of cover images to prefetch for the initial screen.
    private static let prefetchLimit = 24

    /// Prefetches cover image URLs for the given games. Runs on a background queue.
    static func prefetchCoverImages(for games: [Game]) {
        let urls = games
            .prefix(prefetchLimit)
            .compactMap { game -> URL? in
                guard let urlString = game.coverImageURL else { return nil }
                return URL(string: urlString)
            }
        guard !urls.isEmpty else { return }

        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.httpMaximumConnectionsPerHost = 4
        let session = URLSession(configuration: config)

        for url in urls {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            session.dataTask(with: request) { _, _, _ in
                // Fire-and-forget; we're populating the cache
            }.resume()
        }
    }
}
