import XCTest
import EssentialFeed

class LoadFeedFromCacheUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_load_requestsCacheRetrieval () {
        let (sut, store) = makeSUT()

        sut.load() { _ in }

        XCTAssertEqual(store.receivedMessages, [.retrive])
    }

    func test_load_failsOnRetrievalError () {
        let (sut, store) = makeSUT()
        let retrivalError = anyNSError()
        let exp = expectation (description: "Wait for save completion")

        var receivedError: Error?
        sut.load { error in
            receivedError = error
            exp.fulfill()
        }

        store.completeRetrieval(with: retrivalError)
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(receivedError as NSError?, retrivalError)
    }

    // MARK: - Helpers

    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         file: StaticString = #file,
                         line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }

    /*private func expect(_ sut: LocalFeedLoader,
                        toCompletewithError expectedError: NSError?,
                        when action: () -> Void,
                        file: StaticString = #file,
                        line: UInt = #line) {
        let exp = expectation (description: "Wait for save completion")
        var receivedError: Error?
        sut.load(uniqueImageFeed().models) { error in
            receivedError = error
            exp.fulfill()
        }

        action()
        wait(for: [exp])
        XCTAssertEqual(receivedError as NSError?, expectedError, file: file, line: line)
    }*/
}
