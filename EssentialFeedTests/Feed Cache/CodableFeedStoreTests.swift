import XCTest
import EssentialFeed

class CodableFeedStore {
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date

        var localFeed: [LocalFeedImage] {
            feed.map { $0.local }
        }
    }

    private struct CodableFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL

        init(_ image: LocalFeedImage) {
            id = image.id
            description = image.description
            location = image.location
            url = image.url
        }

        var local: LocalFeedImage {
            LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }

    private let storeURL: URL

    init (storeURL: URL) {
        self.storeURL = storeURL
    }

    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            completion(.empty)
            return
        }

        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
    }

    func insert(_ feed: [LocalFeedImage],
                timestamp: Date,
                completion: @escaping FeedStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let cache = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
        let encoded = try! encoder.encode(cache)
        try! encoded.write(to: storeURL)
        completion(nil)
    }
}

final class CodableFeedStoreTests: XCTestCase {

    override func setUp() {
        super.setUp()

        deleteCacheStorage()
    }

    override func tearDown() {
        super.tearDown()

        deleteCacheStorage()
    }

    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeCodableFeedStoreSUT()

        let exp = expectation(description: "Wait for cache retrieval")
        sut.retrieve { result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("Expected empty result, got \(result) instead.")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_retrieve_hasNoSideEffectOnEmptyCache() {
        let sut = makeCodableFeedStoreSUT()

        expect(sut, toRetrieveTwice: .empty)
    }

    func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues() {
        let sut = makeCodableFeedStoreSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()

        insert((feed, timestamp), to: sut)

        expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeCodableFeedStoreSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()

        insert((feed, timestamp), to: sut)
        expect(sut, toRetrieveTwice: .found(feed: feed, timestamp: timestamp))
    }

    // MARK: - Helpers

    private func makeCodableFeedStoreSUT(file: StaticString = #file,
                                         line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date),
                        to sut: CodableFeedStore) {
        let exp = expectation(description: "Wait for cache insertion")
        sut.insert (cache.feed, timestamp: cache.timestamp) { insertionError in
            XCTAssertNil(insertionError, "Expected feed to be inserted successfully")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    private func expect(_ sut: CodableFeedStore,
                        toRetrieveTwice expectedResult: RetrieveCachedFeedResult,
                        file: StaticString = #file,
                        line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }

    private func expect(_ sut: CodableFeedStore,
                        toRetrieve expectedResult: RetrieveCachedFeedResult,
                        file: StaticString = #file,
                        line: UInt = #line) {
        let exp = expectation(description: "Wait for cache retrieval")

        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
            case (.empty, .empty):
                break
            case let (.found(expectedFeed, expectedTimestamp),
                      .found(retrievedFeed, retrievedTimestamp)):
                XCTAssertEqual (retrievedFeed,
                                expectedFeed,
                                file: file,
                                line: line)
                XCTAssertEqual(retrievedTimestamp,
                               expectedTimestamp,
                               file: file,
                               line: line)
            default:
                XCTFail("Expected to retrieve \(expectedResult), got \(retrievedResult) instead",
                        file: file, line: line)
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    private func testSpecificStoreURL() -> URL {
        FileManager.default.urls(for: . cachesDirectory,
                                 in: .userDomainMask)
        .first!.appendingPathComponent("\(type(of: self)).store")
    }

    private func deleteCacheStorage() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
}
