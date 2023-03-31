//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Lynneker Souza on 3/29/23.
//

import Foundation
import XCTest

class RemoteFeedLoader {
    let client: HTTPClient
    let url: URL

    init(client: HTTPClient,
         url: URL) {
        self.url = url
        self.client = client
    }

    func load() {
        client.get(from: url)
    }
}

protocol HTTPClient {
    func get(from url: URL)
}


class RemoteFeedLoaderTests: XCTestCase {
    func test_init_doesNotRequest() {
        let (_, client) = makeSUT()

        XCTAssertNil(client.getFromURL)
    }

    func test_load_requestDataFromURL() {
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load()

        XCTAssertEqual(client.getFromURL, url)
    }

    // MARK: Helpers
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader,
                                                                           client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        return (sut, client)
    }


    private class HTTPClientSpy: HTTPClient {
        private(set) var getFromURL: URL?
        func get(from url: URL) {
            getFromURL = url
        }
    }
}
