import Foundation

public protocol HTTPClient {
    func get(from url: URL)
}


public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient

    public init(client: HTTPClient,
         url: URL) {
        self.url = url
        self.client = client
    }

    func load() {
        client.get(from: url)
    }
}

