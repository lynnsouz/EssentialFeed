import UIKit

protocol FeedRefreshViewControllerDelegate {
    func didRequestFeedRefresh()
}

final class FeedRefreshViewController: NSObject, FeedLoadingView {
    @IBOutlet private var view: UIRefreshControl?

    var delegate: FeedRefreshViewControllerDelegate?

    @IBAction func refresh() {
        delegate?.didRequestFeedRefresh()
    }

    func display(_ viewModel: FeedLoadingViewModel) {
        handleLoadChange(viewModel.isLoading)
    }

    private func handleLoadChange(_ isLoading: Bool) {
        if isLoading {
            view?.beginRefreshing()
        } else {
            view?.endRefreshing()
        }
    }
}
