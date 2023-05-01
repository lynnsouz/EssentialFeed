//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Lynneker Souza on 3/29/23.
//

import Foundation

public enum LoadFeedResult<Error: Swift.Error> {
    case success([FeedItem])
    case failure(Error)
}

protocol FeedLoader {
    associatedtype Error: Swift.Error

    func load(completion: @escaping (LoadFeedResult<Error>) -> Void)
}
