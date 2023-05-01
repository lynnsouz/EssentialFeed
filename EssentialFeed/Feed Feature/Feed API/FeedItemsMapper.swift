import Foundation

internal final class FeedItemsMapper {
    private struct FeedItemsHTTPResponse: Decodable {
        let items: [Item]

        var feed: [FeedItem] {
            return items.map { $0.item }
        }
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

    private static var OK_200: Int { return 200 }

    internal func map(_ data: Data, from response: HTTPURLResponse) -> RemoteFeedLoader.Result {
        guard response.statusCode == FeedItemsMapper.OK_200,
              let root = try? JSONDecoder().decode(FeedItemsHTTPResponse.self, from: data)
        else { return .failure(RemoteFeedLoader.Error.invalidData) }

        return .success(root.feed)
    }
}

