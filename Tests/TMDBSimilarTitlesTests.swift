import Foundation
import XCTest
@testable import WATCHLIST

final class TMDBSimilarTitlesTests: XCTestCase {
    func testSimilarMoviesUsesLocalizedEndpointAndBearerToken() async throws {
        let responseData = """
        {
          "results": [
            {
              "id": 550,
              "title": "Fight Club",
              "overview": "Original title",
              "release_date": "1999-10-15",
              "vote_average": 8.4
            },
            {
              "id": 680,
              "title": "Pulp Fiction",
              "overview": "Similar title",
              "release_date": "1994-10-14",
              "vote_average": 8.5
            }
          ]
        }
        """.data(using: .utf8)!

        StubURLProtocol.responseData = responseData
        StubURLProtocol.statusCode = 200

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        let client = TMDBClient(accessToken: "test-token", session: session)
        let source = MediaItem(
            id: 550,
            kind: .movie,
            title: "Fight Club",
            overview: ""
        )

        let results = try await client.similarTitles(to: source)

        XCTAssertEqual(results.map(\.id), [680])
        XCTAssertEqual(StubURLProtocol.lastRequest?.url?.path, "/3/movie/550/similar")
        XCTAssertEqual(
            URLComponents(url: try XCTUnwrap(StubURLProtocol.lastRequest?.url), resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "language" })?.value,
            "sv-SE"
        )
        XCTAssertEqual(StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
    }

    func testSimilarTelevisionUsesTelevisionEndpoint() async throws {
        StubURLProtocol.responseData = """
        {
          "results": [
            {
              "id": 456,
              "name": "Better Call Saul",
              "overview": "A related series",
              "first_air_date": "2015-02-08",
              "vote_average": 8.9
            }
          ]
        }
        """.data(using: .utf8)!
        StubURLProtocol.statusCode = 200

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        let client = TMDBClient(accessToken: "test-token", session: session)
        let source = MediaItem(
            id: 1396,
            kind: .television,
            title: "Breaking Bad",
            overview: ""
        )

        let results = try await client.similarTitles(to: source)

        XCTAssertEqual(results.map(\.title), ["Better Call Saul"])
        XCTAssertEqual(StubURLProtocol.lastRequest?.url?.path, "/3/tv/1396/similar")
    }
}

private final class StubURLProtocol: URLProtocol {
    private static let lock = NSLock()
    private static var storedResponseData = Data()
    private static var storedStatusCode = 200
    private static var storedLastRequest: URLRequest?

    static var responseData: Data {
        get { lock.lock(); defer { lock.unlock() }; return storedResponseData }
        set { lock.lock(); defer { lock.unlock() }; storedResponseData = newValue }
    }

    static var statusCode: Int {
        get { lock.lock(); defer { lock.unlock() }; return storedStatusCode }
        set { lock.lock(); defer { lock.unlock() }; storedStatusCode = newValue }
    }

    static var lastRequest: URLRequest? {
        get { lock.lock(); defer { lock.unlock() }; return storedLastRequest }
        set { lock.lock(); defer { lock.unlock() }; storedLastRequest = newValue }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        let data = Self.responseData
        let status = Self.statusCode
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
