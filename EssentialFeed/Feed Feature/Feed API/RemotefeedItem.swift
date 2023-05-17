import Foundation

internal struct RemotefeedItem: Decodable {
    internal let id: UUID
    internal let description: String?
    internal let location: String?
    internal let image: URL
}
