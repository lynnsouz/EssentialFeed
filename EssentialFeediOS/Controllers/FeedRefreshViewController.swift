import UIKit

protocol FeedRefreshViewControllerDelegate {
    func didRequestFeedRefresh()
}

final class FeedRefreshViewController: NSObject, FeedLoadingView {
    private(set) lazy var view: UIRefreshControl = loadView()

    private let delegate: FeedRefreshViewControllerDelegate

    init(delegate: FeedRefreshViewControllerDelegate) {
        self.delegate = delegate
    }

    @objc func refresh() {
        delegate.didRequestFeedRefresh()
    }

    private func loadView() -> UIRefreshControl {
        let view = UIRefreshControl()
        view.addTarget(self,action: #selector(refresh), for: .valueChanged)
        return view
    }

    func display(_ viewModel: FeedLoadingViewModel) {
        handleLoadChange(viewModel.isLoading)
    }

    private func handleLoadChange(_ isLoading: Bool) {
        if isLoading {
            view.beginRefreshing()
        } else {
            view.endRefreshing()
        }
    }
}
