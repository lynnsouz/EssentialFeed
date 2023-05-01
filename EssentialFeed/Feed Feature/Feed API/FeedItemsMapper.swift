import Foundation

internal final class FeedItemsMapper {
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

    private static var OK_200: Int { return 200 }

    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == OK_200,
              let response = try? JSONDecoder().decode(FeedItemsHTTPResponse.self, from: data)
        else { throw RemoteFeedLoader.Error.invalidData }
        return response.items.map({ $0.item })
    }
}

