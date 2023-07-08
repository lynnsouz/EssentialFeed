import XCTest
import EssentialFeed

final class CodableFeedStoreTests: XCTestCase, FailableFeedStoreSpecs {
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

        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }

    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeCodableFeedStoreSUT()

        assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
    }

    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeCodableFeedStoreSUT()

        assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeCodableFeedStoreSUT()

        assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
    }

    func test_retrieve_deliversFailureOnRetrievalError() {
        let storeURL = testSpecificStoreURL()
        let sut = makeCodableFeedStoreSUT(storeURL: storeURL)

        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)

        assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
    }

    func test_retrieve_hasNoSideEffectsOnFailure() {
        let storeURL = testSpecificStoreURL()
        let sut = makeCodableFeedStoreSUT(storeURL: storeURL)

        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)

        assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
    }

    func test_insert_deliversNoErrorOnEmptyCache() {
        let sut = makeCodableFeedStoreSUT()

        assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
    }

    func test_insert_deliversNoErrorOnNonEmptyCache() {
        let sut = makeCodableFeedStoreSUT()

        assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
    }

    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeCodableFeedStoreSUT()

        assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
    }

    func test_insert_deliversErrorOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeCodableFeedStoreSUT(storeURL: invalidStoreURL)

        assertThatInsertDeliversErrorOnInsertionError(on: sut)
    }

    func test_insert_hasNoSideEffectsOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeCodableFeedStoreSUT(storeURL: invalidStoreURL)

        assertThatInsertHasNoSideEffectsOnInsertionError(on: sut)
    }

    func test_delete_deliversNoErrorOnEmptyCache() {
        let sut = makeCodableFeedStoreSUT()

        assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
    }

    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeCodableFeedStoreSUT()

        assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
    }

    func test_delete_deliversNoErrorOnNonEmptyCache() {
        let sut = makeCodableFeedStoreSUT()

        assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
    }

    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeCodableFeedStoreSUT()

        assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
    }

    func test_delete_deliversErrorOnDeletionError() {
        let noDeletePermissionURL = cachesDirectory()
        let sut = makeCodableFeedStoreSUT(storeURL: noDeletePermissionURL)

        assertThatDeleteDeliversErrorOnDeletionError(on: sut)
    }

    func test_delete_hasNoSideEffectsOnDeletionError() {
        let noDeletePermissionURL = cachesDirectory()
        let sut = makeCodableFeedStoreSUT(storeURL: noDeletePermissionURL)

        assertThatDeleteHasNoSideEffectsOnDeletionError(on: sut)
    }

    func test_storeSideEffects_runSerially() {
        let sut = makeCodableFeedStoreSUT()

        assertThatSideEffectsRunSerially(on: sut)
    }

    // MARK: - Helpers

    private func makeCodableFeedStoreSUT(storeURL: URL? = nil,
                                         file: StaticString = #file,
                                         line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    @discardableResult
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date),
                        to sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache insertion")
        var insertionError: Error?
        sut.insert(cache.feed, timestamp: cache.timestamp) { result in
            switch result {
            case let .failure(error):
                insertionError = error
                XCTFail("Error.")
            default:
                XCTAssertNil(insertionError, "Expected feed to be inserted successfully")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }

    private func expect(_ sut: FeedStore,
                        toRetrieveTwice expectedResult: FeedStore.RetrievalResult,
                        file: StaticString = #file,
                        line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }

    private func expect(_ sut: FeedStore,
                        toRetrieve expectedResult: FeedStore.RetrievalResult,
                        file: StaticString = #file,
                        line: UInt = #line) {
        let exp = expectation(description: "Wait for cache retrieval")

        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
            case (.success(.none), .success(.none)), (.failure, .failure):
                break
            case let (.success(expectedCache),
                      .success(retrievedCache)):
                XCTAssertEqual (retrievedCache?.feed,
                                expectedCache?.feed,
                                file: file,
                                line: line)
                XCTAssertEqual(retrievedCache?.timestamp,
                               expectedCache?.timestamp,
                               file: file,
                               line: line)
            default:
                XCTFail("Expected to retrieve \(expectedResult), got \(retrievedResult) instead",
                        file: file,
                        line: line)
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    private func testSpecificStoreURL() -> URL {
        cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }

    private func cachesDirectory() -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    private func deleteCacheStorage() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
}
