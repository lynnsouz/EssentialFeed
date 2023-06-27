import XCTest
import EssentialFeed

final class EssentialFeedCacheIntegrationTests: XCTestCase {

    func test_load_deliversNoItemsOnEmptyCache () {
        let sut = makeSUT()
        let exp = expectation(description: "Wait for load completion")
        sut?.load { result in
            switch result {
            case let . success(imageFeed):
                XCTAssertEqual(imageFeed, [], "Expected empty feed")
            case let . failure(error):
                XCTFail("Expected successful feed result, got \(error) instead")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    private func testSpecificStoreURL() -> URL {
        cachesDirectory().appendingPathComponent ("\(type(of: self)).store")
    }

    private func cachesDirectory() -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    public func makeSUT() -> FeedLoader? {
        return nil
    }

}
