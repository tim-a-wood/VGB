import Foundation

/// Client for the IGDB API v4.
///
/// All requests go through `api.igdb.com/v4/` and use the Apicalypse query language
/// in the POST body. Auth is handled via `TwitchAuthManager`.
actor IGDBClient {

    static let shared = IGDBClient()

    private let baseURL = URL(string: "https://api.igdb.com/v4")!
    private let auth = TwitchAuthManager.shared

    private init() {}

    // MARK: - Public API

    /// Search games by title. Returns up to `limit` results.
    func searchGames(_ query: String, limit: Int = 15) async throws -> [IGDBGame] {
        let body = """
        search "\(query.sanitizedForQuery)";
        fields name,cover.image_id,platforms.name,genres.name,involved_companies.company.name,involved_companies.developer,first_release_date,total_rating,summary;
        limit \(limit);
        """
        return try await post(endpoint: "games", body: body)
    }

    /// Fetch a single game by IGDB ID with full details.
    func fetchGame(id: Int) async throws -> IGDBGame? {
        let body = """
        fields name,cover.image_id,platforms.name,genres.name,involved_companies.company.name,involved_companies.developer,first_release_date,total_rating,summary;
        where id = \(id);
        limit 1;
        """
        let results: [IGDBGame] = try await post(endpoint: "games", body: body)
        return results.first
    }

    // MARK: - Private

    private func post<T: Decodable>(endpoint: String, body: String) async throws -> T {
        let url = baseURL.appendingPathComponent(endpoint)
        let token = try await auth.validToken()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(APIConfig.twitchClientID, forHTTPHeaderField: "Client-ID")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw IGDBError.requestFailed(statusCode: 0)
        }

        // If unauthorized, invalidate token and retry once
        if http.statusCode == 401 {
            await auth.invalidate()
            let newToken = try await auth.validToken()

            var retry = request
            retry.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
            let (retryData, retryResponse) = try await URLSession.shared.data(for: retry)

            guard let retryHTTP = retryResponse as? HTTPURLResponse, retryHTTP.statusCode == 200 else {
                throw IGDBError.authFailed
            }

            do {
                return try JSONDecoder().decode(T.self, from: retryData)
            } catch {
                throw IGDBError.decodingFailed(underlying: error)
            }
        }

        guard http.statusCode == 200 else {
            throw IGDBError.requestFailed(statusCode: http.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw IGDBError.decodingFailed(underlying: error)
        }
    }
}

// MARK: - String Sanitization

private extension String {
    /// Escapes quotes for safe use inside an IGDB query string.
    var sanitizedForQuery: String {
        self.replacingOccurrences(of: "\"", with: "\\\"")
    }
}
