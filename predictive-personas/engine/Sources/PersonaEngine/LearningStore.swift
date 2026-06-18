import Foundation

/// The learned data that belongs to one persona layer.
///
/// A pure value type so it can be copied, diffed, and serialized trivially.
/// Two prediction paths are modelled, mirroring how Japanese input works:
///   - `completions`: reading (よみ, e.g. ひらがな) → surface (表記, the word)
///   - `transitions`: previous surface → next surface (predictive next word)
public struct LearningStore: Codable, Equatable {
    /// reading → (surface → stats)
    public private(set) var completions: [String: [String: WordStat]]
    /// previous surface → (next surface → stats)
    public private(set) var transitions: [String: [String: WordStat]]

    public init(completions: [String: [String: WordStat]] = [:],
                transitions: [String: [String: WordStat]] = [:]) {
        self.completions = completions
        self.transitions = transitions
    }

    /// Learn that the user wrote `surface` (read as `reading`), optionally
    /// following the word `previous`.
    public mutating func learn(reading: String, surface: String, previous: String?, at date: Date) {
        guard !surface.isEmpty else { return }
        if !reading.isEmpty {
            completions[reading, default: [:]][surface, default: WordStat(lastUsed: date)].reinforce(at: date)
        }
        if let previous, !previous.isEmpty {
            transitions[previous, default: [:]][surface, default: WordStat(lastUsed: date)].reinforce(at: date)
        }
    }

    /// Candidate words for a given reading, best first.
    public func candidates(forReading reading: String, limit: Int) -> [String] {
        Self.rank(completions[reading], limit: limit)
    }

    /// Likely next words after `surface`, best first.
    public func candidates(after surface: String, limit: Int) -> [String] {
        Self.rank(transitions[surface], limit: limit)
    }

    /// Deterministic ranking: frequency desc, then recency desc, then
    /// lexicographic asc (so results are stable and testable).
    private static func rank(_ map: [String: WordStat]?, limit: Int) -> [String] {
        guard let map, limit > 0 else { return [] }
        return map.sorted { a, b in
            if a.value.count != b.value.count { return a.value.count > b.value.count }
            if a.value.lastUsed != b.value.lastUsed { return a.value.lastUsed > b.value.lastUsed }
            return a.key < b.key
        }
        .prefix(limit)
        .map(\.key)
    }
}
