import Foundation

internal struct RemoteFeedImage: Decodable {
    internal let id: UUID
    internal let description: String?
    internal let location: String?
    internal let image: URL
}
