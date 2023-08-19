import Foundation
import XCTest

extension XCTestCase {
    func trackForMemoryLeaks(_ instance: AnyObject,
                             file: StaticString = #file,
                             line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Should dealocate. Potentoal memory leak.",
                         file: file,
                         line: line)
        }
    }
}

func anyURL(_ string: String = "http://any-url.com") -> URL {
    URL(string: string)!
}

func anyNSError() -> NSError {
    NSError(domain: "any error", code: 0)
}

func anyData() -> Data {
    Data("anv data".utf8)
}

func anyError() -> NSError {
    anyNSError()
}
