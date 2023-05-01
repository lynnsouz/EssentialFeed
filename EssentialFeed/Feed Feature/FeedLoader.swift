//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Lynneker Souza on 3/29/23.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedItem])
    case failure(Error)
}

public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
