import Foundation

private final class FeedCachePolicy {
    private init() {}

    private static let calendar = Calendar(identifier: .gregorian)
    private static var maxCacheAgeInDays: Int {
        return 7
    }

    static func validate(_ timestamp: Date,
                         against date: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day,
                                              value: maxCacheAgeInDays,
                                              to: timestamp)
        else { return false }
        return date < maxCacheAge
    }
}

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
        case let .found(feed, timestamp) where FeedCachePolicy.validate(timestamp, against: currentDate()):
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
        case let .found(_, timestamp) where !FeedCachePolicy.validate(timestamp, against: currentDate()):
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
