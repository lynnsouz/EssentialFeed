import Foundation

public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }

    public init(client: HTTPClient, url: URL) {
        self.url = url
        self.client = client
    }

    func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { result in
            switch result {
            case let .success(data, response):
                guard let items = try? FeedItemsMapper.map(data, response) else {
                    return completion(.failure(.invalidData))
                }
                completion(.success(items))
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}
