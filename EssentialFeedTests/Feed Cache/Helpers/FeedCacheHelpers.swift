import Foundation
import EssentialFeed
import XCTest

extension XCTestCase {
    func makeCachefeedSUT(currentDate: @escaping () -> Date = Date.init,
                 file: StaticString = #file,
                 line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
}

func uniqueImage(id: UUID = UUID(),
                         description: String? = "Any desc.",
                         location: String? = "Any loc.") -> FeedImage {
    FeedImage(id: UUID(),
              description: description,
              location: location,
              url: anyURL())
}

func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
    let items = [uniqueImage(), uniqueImage()]
    let localItems = items.map { LocalFeedImage(id: $0.id,
                                                description: $0.description,
                                                location: $0.location,
                                                url: $0.url) }
    return (items, localItems)
}

extension Date {
    func minusFeedCacheMaxAge() -> Date {
        adding(days: -7)
    }

    func adding(days: Int) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }

    func adding(seconds: TimeInterval) -> Date {
        self + seconds
    }
}
