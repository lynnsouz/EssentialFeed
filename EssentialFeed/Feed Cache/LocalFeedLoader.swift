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
        store.retrive { [weak self] result in
            self?.handleRetrieveResult(result, completion: completion)
        }
    }

    private func handleRetrieveResult(_ result: RetrieveCachedFeedResult,
                                      completion: @escaping (LoadResult) -> Void) {
        switch result {
        case let .failure(error):
            completion(.failure(error))
        case let .found(feed, timestamp) where self.validate(timestamp):
            completion(.success(feed.toModels()))
        case .found, .empty:
            completion(.success([]))
        }
    }

    private func validate(_ timestamp: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        guard let maxCacheAge = calendar.date(byAdding: .day, value: 7, to: timestamp)
        else { return false }
        return currentDate() < maxCacheAge
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
