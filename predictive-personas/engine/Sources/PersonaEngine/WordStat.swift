import Foundation

/// Frequency + recency statistics for a single learned word.
///
/// Kept tiny and `Codable` so that an entire persona's learned data
/// serializes to a small JSON file (= the unit you upload / download / carry).
public struct WordStat: Codable, Equatable {
    public var count: Int
    public var lastUsed: Date

    public init(count: Int = 0, lastUsed: Date = Date()) {
        self.count = count
        self.lastUsed = lastUsed
    }

    /// Record one more use at `date`.
    mutating func reinforce(at date: Date) {
        count += 1
        if date > lastUsed { lastUsed = date }
    }
}
