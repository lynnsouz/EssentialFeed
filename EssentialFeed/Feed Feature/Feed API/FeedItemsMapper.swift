import Foundation

internal struct RemotefeedItem: Decodable {
    internal let id: UUID
    internal let description: String?
    internal let location: String?
    internal let image: URL
}

internal final class FeedItemsMapper {
    private struct FeedItemsHTTPResponse: Decodable {
        let items: [RemotefeedItem]
    }

    private static var OK_200: Int { return 200 }

    internal static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemotefeedItem] {
        guard response.statusCode == FeedItemsMapper.OK_200,
              let root = try? JSONDecoder().decode(FeedItemsHTTPResponse.self, from: data)
        else { throw RemoteFeedLoader.Error.invalidData }

        return root.items
    }
}

