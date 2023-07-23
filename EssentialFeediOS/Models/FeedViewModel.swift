import EssentialFeed

final class FeedViewModel {
    typealias Observer<T> = (T) -> Void

    private let feedLoader: FeedLoader
    init (feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    var onLoadingStateChange: Observer<Bool>?
    var onFeedLoad: Observer<[FeedImage]>?

    func loadFeed() {
        onLoadingStateChange?(true)
        feedLoader.load { [weak self] result in
            self?.handleLoadResult(result)
        }
    }

    private func handleLoadResult(_ result: FeedLoader.Result) {
        if let feed = try? result.get() {
            onFeedLoad?(feed)
        }
        onLoadingStateChange?(false)
    }
}
