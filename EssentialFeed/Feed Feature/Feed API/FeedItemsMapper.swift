import Foundation

final class FeedImagesMapper {
    private struct FeedImagesHTTPResponse: Decodable {
        let items: [RemoteFeedImage]
    }

    private static var OK_200: Int { return 200 }

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedImage] {
        guard response.isOK, let root = try? JSONDecoder().decode(FeedImagesHTTPResponse.self, from: data)
        else { throw RemoteFeedLoader.Error.invalidData }

        return root.items
    }
}
