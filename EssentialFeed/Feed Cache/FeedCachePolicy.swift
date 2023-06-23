import Foundation

public final class FeedCachePolicy {
    private init() {}

    private static let calendar = Calendar(identifier: .gregorian)
    public static var maxCacheAgeInDays: Int {
        return 7
    }

    internal static func validate(_ timestamp: Date,
                         against date: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day,
                                              value: maxCacheAgeInDays,
                                              to: timestamp)
        else { return false }
        return date < maxCacheAge
    }
}
