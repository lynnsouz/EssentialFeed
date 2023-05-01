import XCTest
import EssentialFeed



class URLSessionHTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    struct UnexpectedValuesRepresentation: Error {}
    func get(from url: URL, completion: @escaping (HTTPCLientResult) -> Void) {
        session.dataTask(with: url) {_, _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {

    override class func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptinaRequests()
    }

    override class func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }
    func test_getFromURL_performsGETRequestWithURL() {
        let url = anyURL()
        let exp = expectation(description: "Wait for te block")

        URLProtocolStub.observeRequests { request in
            XCTAssertEqual (request.url, url)
            XCTAssertEqual(request .httpMethod, "GET")
            exp.fulfill()
        }

        makeSUT().get(from: url) { _ in }

        wait(for: [exp], timeout: 1.0)
    }

    func test_getFromURL_failsOnRequestError () {
        let error = NSError (domain: "any error", code: 1)
        URLProtocolStub.stub(url: anyURL(), data: nil, response: nil, error: error)

        let exp = expectation(description: "Wait for te block")
        makeSUT().get(from: anyURL())  { result in
            switch result {
            case let .failure(receivedError as NSError):
                XCTAssertEqual(receivedError.domain, error.domain)
                XCTAssertEqual(receivedError.code, error.code)
            default:
                XCTFail(" Expected Error \(error), got \(result)")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_getFromURL_failsOnAl1NilValues() {
        URLProtocolStub.stub(url: anyURL(), data: nil, response: nil, error: nil)

        let exp = expectation(description: "Wait for te block")
        makeSUT().get(from: anyURL())  { result in
            switch result {
            case .failure: break
            default:
                XCTFail("No error expected, got: \(result)")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    // MARK: - Helpers

    private func anyURL(_ string: String = "http://any-url.com") -> URL {
        URL(string: string)!
    }

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks (sut, file: file, line: line)
        return sut
    }

    private class URLProtocolStub: URLProtocol {
        private static var requestObserver: ((URLRequest) -> Void)?

        private static var stub: Stub?
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }

        static func stub(url: URL, data: Data? , response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        static func observeRequests (observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }

        static func startInterceptinaRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }

        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }

        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }

            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol (self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }

            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }
}
