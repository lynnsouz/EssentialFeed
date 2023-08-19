import EssentialFeed

final class FeedLoaderPresentationAdapter: FeedViewControllerDelegate {
    private let feedLoader: FeedLoader
    var presenter: FeedPresenter?

    init(feedloader: FeedLoader) {
        self.feedLoader = feedloader
    }

    func didRequestFeedRefresh() {
        presenter?.didStartLoadingFeed()
        feedLoader.load { [weak self] result in
            self?.handleLoadedResult(result)
        }
    }

    private func handleLoadedResult(_ result: Result<[FeedImage], Error>) {
        switch result {
        case let .success(feed):
            presenter?.didFinishLoadingFeed (with: feed)
        case let .failure(error):
            presenter?.didFinishLoadingFeed(with: error)
        }
    }
}

