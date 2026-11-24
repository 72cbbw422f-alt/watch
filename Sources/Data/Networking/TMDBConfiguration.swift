import Foundation

enum TMDBConfiguration {
    static var accessToken: String {
        let configuredValue = Bundle.main.object(forInfoDictionaryKey: "TMDBAccessToken") as? String ?? ""
        // Xcode preserves unresolved build-setting references when no local token is configured.
        return configuredValue.hasPrefix("$(") ? "" : configuredValue
    }

    static var isConfigured: Bool {
        !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func makeClient() -> TMDBClient {
        TMDBClient(accessToken: accessToken)
    }
}
