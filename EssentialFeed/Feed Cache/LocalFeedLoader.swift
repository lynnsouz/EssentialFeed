import Foundation

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date

    public typealias SaveResult = Error?
    public typealias LoadResult = LoadFeedResult

    public init(store: FeedStore,
          currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            self?.handleSaveAfterDeleteCache(error: error,
                                             items: feed,
                                             completion: completion)
        }
    }

    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrive { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success([]))
            }
        }
    }

    private func handleSaveAfterDeleteCache(error: Error?, items: [FeedImage], completion: @escaping (Error?) -> Void) {
        if let cacheDeletionError = error {
            completion(cacheDeletionError)
            return
        }
        cache(items, with: completion)
    }

    private func cache(_ items: [FeedImage], with completion: @escaping (Error?) -> Void) {
        store.insert(items.toLocal(), timestamp: self.currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

private extension Array where Element == FeedImage {
    func toLocal () -> [LocalFeedImage] {
        return map { LocalFeedImage(id: $0.id,
                                   description: $0.description,
                                   location: $0.location,
                                   url: $0.url) }
    }
}
