import XCTest
import EssentialFeed



class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    struct UnexpectedValuesRepresentation: Error {}
    func get(from url: URL, completion: @escaping (HTTPCLientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data,
                      let response = response as? HTTPURLResponse {
                completion(.success(data, response))
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
        let exp = expectation(description: "Line: \(#line) - Wait for te block. \(#file), ")

        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request .httpMethod, "GET")
            exp.fulfill()
        }

        makeSUT().get(from: url) { _ in }

        wait(for: [exp], timeout: 1.0)
    }

    func test_getFromURL_failsOnRequestError() {
        let requestError = anyError()
        let receivedError = resultErrorFor(data: nil, response: nil, error: requestError)

        XCTAssertEqual((receivedError as? NSError)?.code, requestError.code)
        XCTAssertEqual((receivedError as? NSError)?.domain, requestError.domain)
    }

    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyError()))
    }

    func test_getFromURL_suceedsOnHTTPURLResponsewithData() {
        let data = anyData()
        let response = anyHTTPURLResponse()

        let result = resultFor(data: data, response: response, error: nil, file: #file, line: #line)

        switch result {
        case let .success(receivedData, receivedResponse):
            XCTAssertEqual(receivedData, data)
            XCTAssertEqual(receivedResponse.url, response.url)
            XCTAssertEqual(receivedResponse.statusCode, response.statusCode)
        default:
            XCTFail("Expected success. got \(result) instead.")
        }

    }

    func test_getFromURL_suceedsWithEmptyDataOnHTTPURLResponseWithNilData() {
        let response = anyHTTPURLResponse()
        let receivedValues = resultValuesFor(data: nil, response: response, error: nil)

        let emptyData = Data()
        XCTAssertEqual(receivedValues?.data, emptyData)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)

    }

    func test_getFromURL_suceedsWithEmptyDataOnHTTPURLResponseWithAnyData() {
        let response = anyHTTPURLResponse()
        let data = anyData()
        let receivedValues = resultValuesFor(data: data, response: response, error: nil)

        XCTAssertNotNil(receivedValues?.data)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)

    }

    // MARK: - Helpers

    private func resultErrorFor(data: Data?,
                                response: URLResponse?,
                                error: Error?,
                                file: StaticString = #file,
                                line: UInt = #line) -> Error? {
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)

        switch result {
        case let .failure(failureError):
            return failureError
        default:
            XCTFail("Expected failure, got: \(result)", file: file, line: line)
            return nil
        }
    }
    
    private func resultValuesFor(data: Data?,
                                 response: URLResponse?,
                                 error: Error?,
                                 file: StaticString = #file,
                                 line: UInt = #line) -> (data: Data, response: HTTPURLResponse)? {
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)

        switch result {
        case let .success(data, response):
            return (data, response)
        default:
            XCTFail("Expected success, got: \(result)", file: file, line: line)
            return nil
        }
    }

    private func resultFor(data: Data?,
                           response: URLResponse?,
                           error: Error?,
                           file: StaticString = #file,
                           line: UInt = #line) -> HTTPCLientResult {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        let exp = expectation(description: "Wait for te block at \(file), \(line)")

        var receivedResult: HTTPCLientResult!
        sut.get(from: anyURL())  { result in
            receivedResult = result
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
        return receivedResult
    }

    private func anyURL(_ string: String = "http://any-url.com") -> URL {
        URL(string: string)!
    }

    private func nonHTTPURLResponse() -> URLResponse {
        URLResponse(url: anyURL(),
                    mimeType: nil,
                    expectedContentLength: 0,
                    textEncodingName: nil)
    }
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        HTTPURLResponse(url: anyURL(),
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil)!
    }
    private func anyData() -> Data {
        Data("anv data".utf8)
    }
    private func anyError() -> NSError {
        NSError(domain: "any error", code: 0)
    }

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
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

        static func stub(data: Data? , response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
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
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }

            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }

            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }
}
