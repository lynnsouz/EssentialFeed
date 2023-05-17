import XCTest
import EssentialFeed

class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date

    init (store: FeedStore,
          currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed { [unowned self] error in
            if error == nil {
                self.store.insert(items, timestamp: self.currentDate())
            }
        }
    }
}

class FeedStore {
    typealias DeletionCompletion = (Error?) -> Void

    enum ReceivedMessage: Equatable {
        case deleteCachedFeed
        case insert ([FeedItem], Date)
    }

    private(set) var receivedMessages = [ReceivedMessage]()

    private var deletionCompletions = [DeletionCompletion] ()

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

    func insert(_ items: [FeedItem], timestamp: Date) {
        receivedMessages.append(.insert(items, timestamp))
    }
}

final class CachefeedUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        let items = [uniqueltem(), uniqueltem()]
        sut.save(items)

        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let items = [uniqueltem(), uniqueltem()]
        let deletionError = anyNSError()

        sut.save(items)
        store.completeDeletion(with: deletionError)

        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }

    func test_save_requestsNewCacheInsertion0nSuccessfulDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let items = [uniqueltem(), uniqueltem()]

        sut.save(items)
        store.completeDeletionSuccessfully()

        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(items, timestamp)])
    }

    // MARK: - Helpers

    func makeSUT(currentDate: @escaping () -> Date = Date.init,file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
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
}
