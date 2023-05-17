import Foundation

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date

    public init(store: FeedStore,
          currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    public func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            self?.handleSaveAfterDeleteCache(error: error,
                                             items: items,
                                             completion: completion)
        }
    }

    private func handleSaveAfterDeleteCache(error: Error?, items: [FeedItem], completion: @escaping (Error?) -> Void) {
        if let cacheDeletionError = error {
            completion(cacheDeletionError)
            return
        }
        cache(items, with: completion)
    }

    private func cache(_ items: [FeedItem], with completion: @escaping (Error?) -> Void) {
        store.insert(items, timestamp: self.currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}
