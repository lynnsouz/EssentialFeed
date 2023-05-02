import XCTest

import EssentialFeed

final class EssentialFeedEndToEndTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_endToEndTestServerGETFeedResultmatchesFixedTestAccountData() {
        switch getFeedResult() {
        case let .success(items)?:
            XCTAssertEqual(items.count, 8, "Expected 8 items in the test account feed")
        case let .failure(error)?:
            XCTFail("Exoected successful feed result, got \(error) instead")
        default:
            XCTFail("Exoected successful feed result, got no result instead")
        }
    }

    // MARK: - Helpers

    private func getFeedResult() -> LoadFeedResult? {
        let testServerURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
        let client = URLSessionHTTPClient()
        let loader = RemoteFeedLoader(client: client, url: testServerURL)

        weak var exp = expectation (description: "Wait for load completion")

        var receivedResult: LoadFeedResult?
        loader.load { result in
            receivedResult = result
            guard let expectation = exp else { return }
            expectation.fulfill()
            exp = nil
        }

        guard let exp = exp else { return nil }
        wait(for: [exp], timeout: 6.0)
        return receivedResult
    }
}
