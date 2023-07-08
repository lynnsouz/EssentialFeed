import Foundation

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date

    public init(store: FeedStore,
                currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
}

extension LocalFeedLoader {
    public typealias SaveResult = Result<Void, Error>

    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] result in
            self?.handleSaveAfterDeleteCache(result: result,
                                             items: feed,
                                             completion: completion)
        }
    }

    private func handleSaveAfterDeleteCache(result: SaveResult,
                                            items: [FeedImage],
                                            completion: @escaping (SaveResult) -> Void) {
        switch result {
        case .success:
            cache(items, with: completion)
        case let .failure(error):
            completion(.failure(error))
        }
    }

    private func cache(_ items: [FeedImage], with completion: @escaping (SaveResult) -> Void) {
        store.insert(items.toLocal(), timestamp: self.currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

extension LocalFeedLoader: FeedLoader {
    public typealias LoadResult = FeedLoader.Result

    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            self?.handleRetrieveResult(result, completion: completion)
        }
    }
    private func handleRetrieveResult(_ result: FeedStore.RetrievalResult,
                                      completion: @escaping (LoadResult) -> Void) {
        switch result {
        case let .failure(error):
            completion(.failure(error))
        case let .success(.some(cache))
            where FeedCachePolicy.validate(cache.timestamp,
                                           against: currentDate()):
            completion(.success(cache.feed.toModels()))
        case .success:
            completion(.success([]))
        }
    }
}

extension LocalFeedLoader {
    public func validateCache() {
        store.retrieve { [weak self] result in
            self?.handleValidateCacheRetrieveResult(result)
        }
    }

    private func handleValidateCacheRetrieveResult(_ result: FeedStore.RetrievalResult) {
        switch result {
        case .failure:
            store.deleteCachedFeed { _ in }
        case let .success(.some(cache))
            where !FeedCachePolicy.validate(cache.timestamp, against: currentDate()):
            store.deleteCachedFeed { _ in }
        case .success: break
        }
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        return map { LocalFeedImage(id: $0.id,
                                    description: $0.description,
                                    location: $0.location,
                                    url: $0.url) }
    }
}

private extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage] {
        return map { FeedImage(id: $0.id,
                               description: $0.description,
                               location: $0.location,
                               url: $0.url) }
    }
}
