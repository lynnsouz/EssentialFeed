import Foundation

private final class FeedCachePolicy {
    private let currentDate: () -> Date
    private let calendar = Calendar(identifier: .gregorian)
    private var maxCacheAgeInDays: Int {
        return 7
    }

    init(currentDate: @escaping () -> Date) {
        self.currentDate = currentDate
    }

    func validate(_ timestamp: Date) -> Bool {

        guard let maxCacheAge = calendar.date(byAdding: .day,
                                              value: maxCacheAgeInDays,
                                              to: timestamp)
        else { return false }
        return currentDate() < maxCacheAge
    }
}

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    private let cachePolicy: FeedCachePolicy

    public init(store: FeedStore,
                currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
        self.cachePolicy = FeedCachePolicy(currentDate: currentDate)
    }
}

extension LocalFeedLoader {
    public typealias SaveResult = Error?

    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            self?.handleSaveAfterDeleteCache(error: error,
                                             items: feed,
                                             completion: completion)
        }
    }

    private func handleSaveAfterDeleteCache(error: Error?, items: [FeedImage],
                                            completion: @escaping (Error?) -> Void) {
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

extension LocalFeedLoader: FeedLoader {
    public typealias LoadResult = LoadFeedResult

    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrive { [weak self] result in
            self?.handleRetrieveResult(result, completion: completion)
        }
    }
    private func handleRetrieveResult(_ result: RetrieveCachedFeedResult,
                                      completion: @escaping (LoadResult) -> Void) {
        switch result {
        case let .failure(error):
            completion(.failure(error))
        case let .found(feed, timestamp) where self.cachePolicy.validate(timestamp):
            completion(.success(feed.toModels()))
        case .found, .empty:
            completion(.success([]))
        }
    }
}

extension LocalFeedLoader {
    public func validateCache() {
        store.retrive { [weak self] result in
            self?.handleValidateCacheRetrieveResult(result)
        }
    }
    
    private func handleValidateCacheRetrieveResult(_ result: RetrieveCachedFeedResult) {
        switch result {
        case .failure:
            store.deleteCachedFeed { _ in }
        case let .found(_, timestamp) where !self.cachePolicy.validate(timestamp):
            store.deleteCachedFeed { _ in }
        case .empty, .found: break
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
