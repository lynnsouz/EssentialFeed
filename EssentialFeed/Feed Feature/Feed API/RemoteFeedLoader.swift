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

private class FeedItemsMapper {
    private struct FeedItemsHTTPResponse: Decodable {
        let items: [Item]
    }

    private struct Item: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL

        var item: FeedItem {
            FeedItem(id: id,
                     description: description,
                     location: location,
                     imageURL: image)
        }
    }
    static var OK_200: Int { return 200 }

    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == OK_200,
              let response = try? JSONDecoder().decode(FeedItemsHTTPResponse.self, from: data)
        else { throw RemoteFeedLoader.Error.invalidData }
        return response.items.map({ $0.item })
    }
}

