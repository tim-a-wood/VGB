import Foundation

/// Manages Twitch OAuth2 app access tokens using the client credentials flow.
///
/// Tokens are cached in memory and automatically refreshed when expired.
actor TwitchAuthManager {

    static let shared = TwitchAuthManager()

    private var accessToken: String?
    private var expiresAt: Date?

    private let tokenURL = URL(string: "https://id.twitch.tv/oauth2/token")!

    private init() {}

    // MARK: - Public

    /// Returns a valid access token, fetching or refreshing as needed.
    func validToken() async throws -> String {
        if let token = accessToken, let expires = expiresAt, Date() < expires {
            return token
        }
        return try await fetchToken()
    }

    /// Forces a token refresh (e.g., after a 401 response).
    func invalidate() {
        accessToken = nil
        expiresAt = nil
    }

    // MARK: - Private

    private func fetchToken() async throws -> String {
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "client_id": APIConfig.twitchClientID,
            "client_secret": APIConfig.twitchClientSecret,
            "grant_type": "client_credentials"
        ]
        request.httpBody = body
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw IGDBError.authFailed
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        self.accessToken = tokenResponse.accessToken
        // Expire 60 seconds early to avoid edge-case failures
        self.expiresAt = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn - 60))

        return tokenResponse.accessToken
    }
}

// MARK: - Token Response

private struct TokenResponse: Decodable {
    let accessToken: String
    let expiresIn: Int
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}
