import Foundation
import EssentialFeed

internal class FeedStoreSpy: FeedStore {

    enum ReceivedMessage: Equatable {
        case deleteCachedFeed
        case insert([LocalFeedImage], Date)
        case retrive
    }

    private(set) var receivedMessages = [ReceivedMessage]()

    private var deletionCompletions = [DeletionCompletion]()
    private var insertionCompletions = [InsertionCompletion]()
    private var retrievalCompletions = [RetrievalCompletion]()

    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedFeed)
    }

    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }

    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }

    func insert(_ items: [EssentialFeed.LocalFeedImage],
                timestamp: Date, completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        receivedMessages.append(.insert(items, timestamp))
    }

    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }

    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }

    func retrive(completion: @escaping RetrievalCompletion) {
        retrievalCompletions.append(completion)
        receivedMessages.append(.retrive)
    }

    func completeRetrieval(with error: Error, at index: Int = 0) {
        retrievalCompletions[index](error)
    }
}
