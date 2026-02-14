import Foundation

/// Reads API credentials from Info.plist (injected via Secrets.xcconfig).
enum APIConfig {

    static var twitchClientID: String {
        guard let value = Bundle.main.infoDictionary?["TwitchClientID"] as? String,
              !value.isEmpty,
              value != "YOUR_CLIENT_ID_HERE" else {
            fatalError("Missing TWITCH_CLIENT_ID — copy Secrets.xcconfig.example to Secrets.xcconfig and fill in your Twitch credentials.")
        }
        return value
    }

    static var twitchClientSecret: String {
        guard let value = Bundle.main.infoDictionary?["TwitchClientSecret"] as? String,
              !value.isEmpty,
              value != "YOUR_CLIENT_SECRET_HERE" else {
            fatalError("Missing TWITCH_CLIENT_SECRET — copy Secrets.xcconfig.example to Secrets.xcconfig and fill in your Twitch credentials.")
        }
        return value
    }
}
