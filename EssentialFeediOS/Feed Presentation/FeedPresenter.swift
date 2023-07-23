import EssentialFeed

protocol FeedLoadingView: AnyObject {
    func display(isLoading: Bool)
}
protocol FeedView {
    func display(feed: [FeedImage])
}

final class FeedPresenter {
    typealias Observer<T> = (T) -> Void

    private let feedLoader: FeedLoader
    init (feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    var feedView: FeedView?
    weak var loadingView: FeedLoadingView?

    func loadFeed() {
        loadingView?.display(isLoading: true)
        feedLoader.load { [weak self] result in
            self?.handleLoadResult(result)
        }
    }

    private func handleLoadResult(_ result: FeedLoader.Result) {
        if let feed = try? result.get() {
            feedView?.display(feed: feed)
        }
        loadingView?.display(isLoading: false)
    }
}
