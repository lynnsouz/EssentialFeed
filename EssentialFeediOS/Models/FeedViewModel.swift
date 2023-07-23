import EssentialFeed

final class FeedViewModel {
    private let feedLoader: FeedLoader
    init (feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    var onChange: ((FeedViewModel) -> Void)?
    var onFeedLoad: (([FeedImage]) -> Void)?


    private(set) var isLoading: Bool = false {
        didSet { onChange?(self) }
    }

    func loadFeed() {
        isLoading = true
        feedLoader.load { [weak self] result in
            self?.handleLoadResult(result)
        }
    }

    private func handleLoadResult(_ result: FeedLoader.Result) {
        if let feed = try? result.get() {
            onFeedLoad?(feed)
        }
        isLoading = false
    }
}
