import Foundation

extension HTTPURLResponse {
    private static var OK_200: Int { return 200 }
    var isOK: Bool {
        statusCode == HTTPURLResponse.OK_200
    }
}
