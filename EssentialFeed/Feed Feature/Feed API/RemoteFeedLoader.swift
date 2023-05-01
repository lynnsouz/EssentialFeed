import Foundation

public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public typealias Result = LoadFeedResult<Error>

    public init(client: HTTPClient, url: URL) {
        self.url = url
        self.client = client
    }

    func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            self?.handleLoadResult(result, completion: completion)
        }
    }

    private func handleLoadResult(_ result: HTTPCLientResult,
                                  completion: @escaping (Result) -> Void) {
        switch result {
        case let .success(data, response):
            completion(FeedItemsMapper().map(data, from: response))
        case .failure:
            completion(.failure(.connectivity))
        }
    }
}
