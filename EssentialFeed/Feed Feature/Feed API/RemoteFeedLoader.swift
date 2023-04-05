import Foundation

public enum HTTPCLientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPCLientResult) -> Void)
}


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
            case let .success(data, _):
                guard let response = try? JSONDecoder().decode(FeedItemsHTTPResponse.self, from: data) else {
                    return completion(.failure(.invalidData))
                }
                completion(.success(response.items))
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}

private struct FeedItemsHTTPResponse: Decodable {
    let items: [FeedItem]
}
