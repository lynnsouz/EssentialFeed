import XCTest
import EssentialFeed

class URLSessionHTTClient {
    private let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func get(from url: URL, completion: @escaping (HTTPCLientResult) -> Void) {
        session.dataTask(with: url) {_, _, error in
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    func test_getFromURL_resumesDataTaskWithURL() {
        let url = URL(string: "http://any-url.com")!
        let session = URLSessionSpy()
        let task = URLSessionDataTaskSpy()
        session.stub(url: url, task: task)
        let sut = URLSessionHTTClient(session: session)

        sut.get(from: url) { _ in }

        XCTAssertEqual(task.resumeCallCount, 1)
    }

    func test_getFromURL_failsOnRequestError () {
        let url = URL(string: "http://any-url.com")!
        let session = URLSessionSpy()
        let error = NSError (domain: "any error", code: 1)
        session.stub(url: url, error: error)
        let sut = URLSessionHTTClient(session: session)

        let exp = expectation(description: "Wait for te block")
        sut.get(from: url)  { result in
            switch result {
            case let .failure(receivedError as NSError):
                XCTAssertEqual(receivedError, error)
            default:
                XCTFail(" Expected Error \(error), got \(result)")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    // MARK: - Helpers

    private class URLSessionSpy: URLSession {
        private var stubs = [URL: Stub]()

        private struct Stub {
            let task: URLSessionDataTask
            let error: Error?
        }

        func stub(url: URL,
                  task: URLSessionDataTask = FakeURLSessionDataTask(),
                  error: Error? = nil) {
            stubs[url] = Stub(task: task, error: error)
        }

        override func dataTask(with url: URL,
                               completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            guard let stub = stubs[url] else {
                fatalError("No Stub fro this URL")
            }
            completionHandler (nil, nil, stub.error)
            return stub.task
        }
    }

    private class FakeURLSessionDataTask: URLSessionDataTask {
        override func resume() {}
    }

    private class URLSessionDataTaskSpy: URLSessionDataTask {
        var resumeCallCount = 0
        override func resume() {
            resumeCallCount += 1
        }
    }
}
