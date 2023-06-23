import XCTest
import EssentialFeed

class LoadFeedFromCacheUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeCachefeedSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_load_requestsCacheRetrieval () {
        let (sut, store) = makeCachefeedSUT()

        sut.load() { _ in }

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_failsOnRetrievalError () {
        let (sut, store) = makeCachefeedSUT()
        let retrivalError = anyNSError()

        expect(sut, toCompletewith: .failure(retrivalError)) {
            store.completeRetrieval(with: retrivalError)
        }
    }

    func test_load_deliversNoImagesOnEmptyCache() {
        let (sut, store) = makeCachefeedSUT()

        expect(sut, toCompletewith: .success([])) {
            store.completeRetrievalWithEmptyCache()
        }
    }

    func test_load_deliversCachedImagesOnLessThanSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeCachefeedSUT(currentDate: { fixedCurrentDate })

        expect(sut, toCompletewith: .success(feed.models)) {
            store.completeRetrieval(with: feed.local,
                                    timestamp: lessThanSevenDaysOldTimestamp)
        }
    }

    func test_load_deliversNoImagesOnSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
        let (sut, store) = makeCachefeedSUT(currentDate: { fixedCurrentDate })

        expect(sut, toCompletewith: .success([])) {
            store.completeRetrieval(with: [],
                                    timestamp: sevenDaysOldTimestamp)
        }
    }

    func test_load_deliversNoImagesOnMoreSevenDaysOldCache() {
        let fixedCurrentDate = Date()
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
        let (sut, store) = makeCachefeedSUT(currentDate: { fixedCurrentDate })

        expect(sut, toCompletewith: .success([])) {
            store.completeRetrieval(with: [],
                                    timestamp: sevenDaysOldTimestamp)
        }
    }

    func test_load_hasNoSideEffectsOnRetrievalError() {
        let (sut, store) = makeCachefeedSUT()

        sut.load { _ in }
        store.completeRetrieval(with: anyNSError())

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_hasNoSideEffectsOnEmptyCache() {
        let (sut, store) = makeCachefeedSUT()

        sut.load { _ in }
        store.completeRetrievalWithEmptyCache()

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_hasNoSideEffectsOnLessThanSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeCachefeedSUT(currentDate: { fixedCurrentDate })

        sut.load { _ in }
        store.completeRetrieval(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_deletesCacheOnSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
        let (sut, store) = makeCachefeedSUT(currentDate: { fixedCurrentDate })

        sut.load { _ in }
        store.completeRetrieval(with: feed.local, timestamp: sevenDaysOldTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }

    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)

        var receivedResults = [LocalFeedLoader.LoadResult]()
        sut?.load{ receivedResults.append($0) }

        sut = nil
        store.completeRetrievalWithEmptyCache()

        XCTAssertTrue(receivedResults.isEmpty)
    }

    // MARK: - Helpers

    private func expect(_ sut: LocalFeedLoader,
                        toCompletewith expectedResult: LocalFeedLoader.LoadResult,
                        when action: () -> Void,
                        file: StaticString = #file,
                        line: UInt = #line) {
        let exp = expectation (description: "Wait for save completion")

        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedImages), .success(expectedImages)):
                XCTAssertEqual(receivedImages, expectedImages, file: file,line: line)
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError, expectedError, file: file,line: line)
            default:
                XCTFail("Expeceted: \(expectedResult), got: \(receivedResult)", file: file,line: line)
            }
            exp.fulfill()
        }

        action()
        wait(for: [exp])
    }
}
