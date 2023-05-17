import XCTest
import EssentialFeed

final class CachefeedUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        let items = [uniqueltem(), uniqueltem()]
        sut.save(items) { _ in }

        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let items = [uniqueltem(), uniqueltem()]
        let deletionError = anyNSError()

        sut.save(items) { _ in }
        store.completeDeletion(with: deletionError)

        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }

    func test_save_requestsNewCacheInsertion0nSuccessfulDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let items = [uniqueltem(), uniqueltem()]

        sut.save(items) { _ in }
        store.completeDeletionSuccessfully()

        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(items, timestamp)])
    }

    func test_save_failsOnDeletionError() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let deletionError = anyNSError()

        expect(sut, toCompletewithError: deletionError) {
            store.completeDeletion(with: deletionError)
        }
    }

    func test_save_failsOnInsertionError () {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let insertionError = anyNSError()

        expect(sut, toCompletewithError: insertionError) {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        }
    }

    func test_save_succeedsOnSuccessfulCacheInsertion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })

        expect(sut, toCompletewithError: nil) {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        }
    }

    func test_save_doesNotDeliverDeletionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)

        var receivedResults = [Error?]()
        sut?.save([uniqueltem()]) { receivedResults.append ($0) }

        sut = nil
        store.completeDeletion(with: anyNSError())

        XCTAssertTrue(receivedResults.isEmpty)
    }

    func test_save_doesNotDeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)

        var receivedResults = [Error?]()
        sut?.save([uniqueltem()]) { receivedResults.append ($0) }

        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: anyNSError())

        //XCTAssertTrue(receivedResults.isEmpty)
    }

    // MARK: - Helpers

    private func expect(_ sut: LocalFeedLoader,
                        toCompletewithError expectedError: NSError?,
                        when action: () -> Void,
                        file: StaticString = #file,
                        line: UInt = #line) {
        let exp = expectation (description: "Wait for save completion")
        var receivedError: Error?
        sut.save([uniqueltem()]) { error in
            receivedError = error
            exp.fulfill()
        }

        action()
        wait(for: [exp])
        XCTAssertEqual(receivedError as NSError?, expectedError, file: file, line: line)
    }


    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         file: StaticString = #file,
                         line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }

    private func uniqueltem(id: UUID = UUID(),
                            description: String? = "Any desc.",
                            location: String? = "Any loc.") -> FeedItem {
        FeedItem(id: UUID(),
                 description: description,
                 location: location,
                 imageURL: anyURL())
    }

    private func anyNSError() -> NSError {
        NSError(domain: "any error", code: 0)
    }

    private class FeedStoreSpy: FeedStore {

        enum ReceivedMessage: Equatable {
            case insertCache
            case deleteCachedFeed
            case insert([FeedItem], Date)
        }

        private(set) var receivedMessages = [ReceivedMessage]()

        private var deletionCompletions = [DeletionCompletion]()
        private var insertionCompletions = [InsertionCompletion]()

        func deleteCachedFeed(completion: @escaping DeletionCompletion) {
            deletionCompletions.append(completion)
            receivedMessages.append(.deleteCachedFeed)
        }

        func completeDeletion(with error: Error, at index: Int = 0) {
            deletionCompletions[index](error)
        }

        func completeDeletionSuccessfully(at index: Int = 0) {
            deletionCompletions[index](nil)
        }

        func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion) {
            insertionCompletions.append(completion)
            receivedMessages.append(.insert(items, timestamp))
        }

        func completeInsertion(with error: Error, at index: Int = 0) {
            insertionCompletions[index](error)
        }

        func completeInsertionSuccessfully(at index: Int = 0) {
            insertionCompletions[index](nil)
        }
    }
}
