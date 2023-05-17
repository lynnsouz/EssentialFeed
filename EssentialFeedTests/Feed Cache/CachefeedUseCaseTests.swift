import XCTest
import EssentialFeed

class FeedStore {
    var deleteCachedFeedCallCount = 0

    func deleteCachedFeed() {
        deleteCachedFeedCallCount += 1
    }
}


class LocalFeedLoader {
    private let store: FeedStore
    init (store: FeedStore) {
        self.store = store
    }

    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed()
    }
}

final class CachefeedUseCaseTests: XCTestCase {

    func test_init_doesNotDeleteCacheUponCreation() {
        let store = FeedStore()
        _ = LocalFeedLoader(store: store)

        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }

    func test_save_requestsCacheDeletion() {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)

        let items = [uniqueltem(), uniqueltem()]
        sut.save(items)
        XCTAssertEqual(store.deleteCachedFeedCallCount, 1)
    }

    // MARK: - Helpers

    private func uniqueltem(id: UUID = UUID(),
                            description: String? = "Any desc.",
                            location: String? = "Any loc.") -> FeedItem {
        FeedItem(id: UUID(),
                 description: description,
                 location: location,
                 imageURL: anyURL())
    }
}
