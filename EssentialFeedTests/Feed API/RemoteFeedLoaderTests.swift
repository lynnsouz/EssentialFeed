import Foundation
import XCTest

@testable import EssentialFeed

class RemoteFeedLoaderTests: XCTestCase {
    func test_init_doesNotRequest() {
        let (_, client) = makeSUT()

        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    func test_load_requestDataFromURL() {
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load() { _ in }

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_load_requestDataFromURLMoreThanOnce() {
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load() { _ in }
        sut.load() { _ in }

        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWithResult: .failure(.connectivity)) {
            let clientError = NSError (domain: "Test", code: 0)
            client.complete(with: clientError)
        }
    }

    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()

        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWithResult: .failure(.invalidData)) {
                let data = makeItemsJSON([])
                client.complete (withStatusCode: code,
                                 data: data,
                                 at: index)
            }
        }
    }

    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWithResult: .failure(.invalidData)) {
            let invalidJSON = Data("invalid ison".utf8)
            client.complete (withStatusCode: 200, data: invalidJSON)
        }
    }

    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWithResult: .success([])) {
            let emptyListJSON = makeItemsJSON([])
            client.complete (withStatusCode: 200, data: emptyListJSON)
        }
    }

    func test_load_deliversItemsOn200HTTPResponseWithItems() {
        let (sut, client) = makeSUT()

        let (item1, item1JSON) = makeFeedItem(item: .stub(id: UUID(),
                                                          description: nil,
                                                          location: nil,
                                                          imageURL: URL(string: "http://a-url.com")!))

        let (item2, item2JSON) = makeFeedItem(item: .stub(id: UUID(),
                                                          description: "a description",
                                                          location: "a Location",
                                                          imageURL: URL(string: "http://other-url.com")!))

        let itemsJSON = [item1JSON, item2JSON]

        expect(sut, toCompleteWithResult: .success([item1, item2])) {
            let json = makeItemsJSON(itemsJSON)
            client.complete (withStatusCode: 200, data: json)
        }
    }

    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let url = URL(string: "http://any-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(client: client, url: url)

        var capturedResults = [RemoteFeedLoader.Result]()
        sut?.load { capturedResults.append ($0) }

        sut = nil
        client.complete(withStatusCode: 200, data: makeItemsJSON([]))

        XCTAssertTrue(capturedResults.isEmpty)
    }

    // MARK: Helpers
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: RemoteFeedLoader,
                                                                           client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(client, file: file, line: line)
        return (sut, client)
    }

    private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Should dealocate. Potentoal memory leak.", file: file, line: line)
        }
    }

    private func makeFeedItem(item: FeedItem = .stub()) -> (model: FeedItem,
                                                            json: [String: Any]) {
        let json: [String: Any] = [
            "id": item.id.uuidString,
            "description": item.description,
            "location": item.location,
            "image": item.imageURL.absoluteString
        ].compactMapValues { $0 }

        return (item, json)
    }

    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let itemsJSON = ["items": items]
        return try! JSONSerialization.data(withJSONObject: itemsJSON)
    }
    private func expect(_ sut: RemoteFeedLoader,
                        toCompleteWithResult result: RemoteFeedLoader.Result,
                        when action: () -> Void,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load { capturedResults.append ($0) }
        action()
        XCTAssertEqual(capturedResults, [result], file: file, line: line)
    }

    private class HTTPClientSpy: HTTPClient {
        var requestedURLs: [URL] {
            return messages.map { $0.url }
        }

        private(set) var messages = [(url: URL, completion: (HTTPCLientResult) -> Void)]()

        func get(from url: URL, completion: @escaping (HTTPCLientResult) -> Void) {
            messages.append((url, completion))
        }

        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }

        func complete(withStatusCode code: Int,
                      data: Data,
                      at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index],
                                           statusCode: code,
                                           httpVersion: nil,
                                           headerFields: nil)!
            messages[index].completion(.success(data, response))
        }
    }
}

extension FeedItem {
    static func stub(id: UUID = UUID(),
                     description: String? = nil,
                     location: String? = nil,
                     imageURL: URL = URL(string: "https://a-url.com")!) -> FeedItem {
        FeedItem(id: id,
                 description: description,
                 location: location,
                 imageURL: imageURL)
    }
}
