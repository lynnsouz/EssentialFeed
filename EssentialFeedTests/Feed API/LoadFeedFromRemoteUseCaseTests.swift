import Foundation
import XCTest

@testable import EssentialFeed

class LoadFeedFromRemoteUseCaseTests: XCTestCase {
//    func test_init_doesNotRequest() {
//        let (_, client) = makeSUT()
//
//        XCTAssertTrue(client.requestedURLs.isEmpty)
//    }
//
//    func test_load_requestDataFromURL() {
//        let url = URL(string: "https://a-url.com")!
//        let (sut, client) = makeSUT(url: url)
//
//        sut.load() { _ in }
//
//        XCTAssertEqual(client.requestedURLs, [url])
//    }
//
//    func test_load_requestDataFromURLMoreThanOnce() {
//        let url = URL(string: "https://a-url.com")!
//        let (sut, client) = makeSUT(url: url)
//
//        sut.load() { _ in }
//        sut.load() { _ in }
//
//        XCTAssertEqual(client.requestedURLs, [url, url])
//    }
//
//    func test_load_deliversErrorOnClientError() {
//        let (sut, client) = makeSUT()
//
//        expect(sut, toCompleteWithResult: failure(.connectivity)) {
//            let clientError = NSError (domain: "Test", code: 0)
//            client.complete(with: clientError)
//        }
//    }
//
//    func test_load_deliversErrorOnNon200HTTPResponse() {
//        let (sut, client) = makeSUT()
//
//        let samples = [199, 201, 300, 400, 500]
//        samples.enumerated().forEach { index, code in
//            expect(sut, toCompleteWithResult: failure(.invalidData)) {
//                let data = makeItemsJSON([])
//                client.complete (withStatusCode: code,
//                                 data: data,
//                                 at: index)
//            }
//        }
//    }
//
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, _) = makeSUT(stub: { url in
                .failure(anyNSError())
        })

        expect(sut, toCompleteWithResult: failure(.connectivity), when: {})
    }

    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let json = makeItemsJSON([])
        let (sut, _) = makeSUT(stub: { url in
                .success((json, HTTPURLResponse()))
        })

        expect(sut, toCompleteWithResult: .success([]), when: {})
    }

    func test_load_deliversItemsOn200HTTPResponseWithItems() {
        let (item1, item1JSON) = makeFeedImage(item: .stub(id: UUID(),
                                                           description: nil,
                                                           location: nil,
                                                           imageURL: URL(string: "http://a-url.com")!))

        let (item2, item2JSON) = makeFeedImage(item: .stub(id: UUID(),
                                                           description: "a description",
                                                           location: "a Location",
                                                           imageURL: URL(string: "http://other-url.com")!))
        let itemsJSON = [item1JSON, item2JSON]
        let json = makeItemsJSON(itemsJSON)

        let (sut, _) = makeSUT(stub: { url in
                .success((json, HTTPURLResponse()))
        })

        expect(sut, toCompleteWithResult: .success([item1, item2]), when: {})
    }

    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let json = makeItemsJSON([])
        let url = URL(string: "http://any-url.com")!
        let client = HTTPClientSpy(stub: { url in
                .success((json, HTTPURLResponse()))
        })
        var sut: RemoteFeedLoader? = RemoteFeedLoader(client: client, url: url)

        guard let newSut = sut else {
            XCTFail("Sut not valid")
            return
        }
        expect(newSut, toCompleteWithResult: .success([]), when: {

        })

        sut = nil
        sut?.load { receivedResult in
            XCTFail("Not suppose to answer.")
        }
    }

    // MARK: Helpers
    private func makeSUT(stub: @escaping (URL) -> HTTPClient.Result,
                         url: URL = URL(string: "https://a-url.com")!,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: RemoteFeedLoader,
                                                 client: HTTPClientSpy) {
        let client = HTTPClientSpy(stub: stub)
        let sut = RemoteFeedLoader(client: client, url: url)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(client, file: file, line: line)
        return (sut, client)
    }

    private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        .failure(error)
    }

    private func makeFeedImage(item: FeedImage = .stub()) -> (model: FeedImage,
                                                            json: [String: Any]) {
        let json: [String: Any] = [
            "id": item.id.uuidString,
            "description": item.description,
            "location": item.location,
            "image": item.url.absoluteString
        ].compactMapValues { $0 }

        return (item, json)
    }

    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let itemsJSON = ["items": items]
        return try! JSONSerialization.data(withJSONObject: itemsJSON)
    }
    private func expect(_ sut: RemoteFeedLoader,
                        toCompleteWithResult expectedResult: RemoteFeedLoader.Result,
                        when action: () -> Void,
                        file: StaticString = #filePath,
                        line: UInt = #line) {

        let exp = expectation(description: "Wait for load completion" )

        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
            case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected result \(expectedResult) got \(receivedResult) instead",
                        file: file, line:line)
            }

            exp.fulfill()
        }
        action()

        wait(for: [exp])
    }

    private class HTTPClientSpy: HTTPClient {
        private class Task: HTTPClientTask {
            func cancel() {}
        }

        private let stub: (URL) -> HTTPClient.Result

        init(stub: @escaping (URL) -> HTTPClient.Result) {
            self.stub = stub
        }

        func get(from url: URL,
                 completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
            completion(stub(url))
            return Task()
        }

        static var offline: HTTPClientSpy {
            HTTPClientSpy(stub: { _ in .failure(NSError(domain: "offline", code: 0)) })
        }

        static func online(_ stub: @escaping (URL) -> (Data, HTTPURLResponse)) -> HTTPClientSpy {
            HTTPClientSpy { url in .success(stub(url)) }
        }
    }
}

extension FeedImage {
    static func stub(id: UUID = UUID(),
                     description: String? = nil,
                     location: String? = nil,
                     imageURL: URL = URL(string: "https://a-url.com")!) -> FeedImage {
        FeedImage(id: id,
                 description: description,
                 location: location,
                 url: imageURL)
    }
}
