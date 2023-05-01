import XCTest

class URLSessionHTTClient {
    private let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func get(from url: URL) {
        session.dataTask(with: url) {_, _, _ in }
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    func test() {
        let url = URL(string: "http://any-url.com")!
        let session = URLSessionSpy()
        let sut = URLSessionHTTClient(session: session)

        sut.get(from: url)

        XCTAssertEqual(session.receivedURLs, [url])
    }

    // MARK: - Helpers

    private class URLSessionSpy: URLSession {
        var receivedURLs = [URL]()


        override func dataTask(with url: URL,
                               completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            receivedURLs.append(url)

            return FakeURLSessionDataTask()
        }
    }

    private class FakeURLSessionDataTask: URLSessionDataTask {}
}
