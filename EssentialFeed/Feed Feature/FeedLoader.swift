//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Lynneker Souza on 3/29/23.
//

import Foundation

enum LoadFeedResult {
    case success([FeedItem])
    case error(Error)
}

protocol FeedLoader {
    func load(completition: @escaping (LoadFeedResult) -> Void)
}
