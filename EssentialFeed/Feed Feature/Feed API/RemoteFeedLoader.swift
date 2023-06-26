import Foundation

public final class RemoteFeedLoader: FeedLoader {
    private let url: URL
    private let client: HTTPClient

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public typealias Result = LoadFeedResult

    public init(client: HTTPClient, url: URL) {
        self.url = url
        self.client = client
    }

    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            self?.handleLoadResult(result, completion: completion)
        }
    }

    private func handleLoadResult(_ result: HTTPClient.Result,
                                  completion: @escaping (Result) -> Void) {
        switch result {
        case let .success((data, response)):
            completion(RemoteFeedLoader.map(data, from: response))
        case .failure:
            completion(.failure(RemoteFeedLoader.Error.connectivity))
        }
    }

    private static func map(_ data: Data, from response: HTTPURLResponse) -> Result {
        do {
            let items = try FeedImagesMapper.map(data, from: response)
            return .success(items.toModels())
        } catch {
            return .failure(error)
        }
    }
}

private extension Array where Element == RemoteFeedImage {
    func toModels ( ) -> [FeedImage] {
        map { FeedImage(id: $0.id,
                       description: $0.description,
                       location: $0.location,
                       url: $0.image) }
    }
}
