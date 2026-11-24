import Foundation

enum TMDBConfiguration {
    static var accessToken: String {
        Bundle.main.object(forInfoDictionaryKey: "TMDBAccessToken") as? String ?? ""
    }

    static var isConfigured: Bool {
        !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func makeClient() -> TMDBClient {
        TMDBClient(accessToken: accessToken)
    }
}
