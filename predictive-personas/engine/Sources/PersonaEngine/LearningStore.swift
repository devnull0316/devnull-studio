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

    // MARK: - Learning

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

    // MARK: - Candidate retrieval

    /// Candidate words for a given reading, best first.
    ///
    /// - Parameters:
    ///   - now: When provided, applies exponential recency decay so that
    ///     old high-frequency words can be beaten by fresher low-frequency ones.
    ///     Pass `nil` (default) to rank by raw count, then recency, then lex.
    ///   - halfLife: Decay half-life in seconds (default 30 days). Ignored when `now` is nil.
    public func candidates(forReading reading: String, limit: Int,
                           now: Date? = nil,
                           halfLife: TimeInterval = 30 * 86_400) -> [String] {
        Self.rank(completions[reading], limit: limit, now: now, halfLife: halfLife)
    }

    /// Likely next words after `surface`, best first.
    public func candidates(after surface: String, limit: Int,
                           now: Date? = nil,
                           halfLife: TimeInterval = 30 * 86_400) -> [String] {
        Self.rank(transitions[surface], limit: limit, now: now, halfLife: halfLife)
    }

    // MARK: - Pruning

    /// Trim learning data to stay within memory bounds.
    ///
    /// - Parameters:
    ///   - keepPerReading: Maximum number of surface forms to keep per reading key.
    ///   - maxReadings: Maximum number of distinct reading keys to keep in each table.
    ///     Keys with the lowest total usage are dropped first.
    public mutating func prune(keepPerReading: Int = 20, maxReadings: Int = 500) {
        completions = Self.trimTable(completions, keepPerEntry: keepPerReading, maxKeys: maxReadings)
        transitions = Self.trimTable(transitions, keepPerEntry: keepPerReading, maxKeys: maxReadings)
    }

    // MARK: - Private helpers

    /// Deterministic ranking with optional recency decay.
    ///
    /// Without decay (now == nil): count desc → lastUsed desc → lexicographic asc.
    /// With decay: decayed-score desc → lexicographic asc.
    static func rank(_ map: [String: WordStat]?, limit: Int,
                     now: Date? = nil,
                     halfLife: TimeInterval = 30 * 86_400) -> [String] {
        guard let map, limit > 0 else { return [] }
        if let now {
            return map.sorted { a, b in
                let sa = decayedScore(a.value, now: now, halfLife: halfLife)
                let sb = decayedScore(b.value, now: now, halfLife: halfLife)
                if sa != sb { return sa > sb }
                return a.key < b.key
            }
            .prefix(limit)
            .map(\.key)
        } else {
            return map.sorted { a, b in
                if a.value.count != b.value.count { return a.value.count > b.value.count }
                if a.value.lastUsed != b.value.lastUsed { return a.value.lastUsed > b.value.lastUsed }
                return a.key < b.key
            }
            .prefix(limit)
            .map(\.key)
        }
    }

    private static func decayedScore(_ stat: WordStat, now: Date, halfLife: TimeInterval) -> Double {
        let elapsed = max(0, now.timeIntervalSince(stat.lastUsed))
        return Double(stat.count) * pow(0.5, elapsed / halfLife)
    }

    private static func trimTable(
        _ map: [String: [String: WordStat]],
        keepPerEntry: Int,
        maxKeys: Int
    ) -> [String: [String: WordStat]] {
        // Step 1: trim each key's candidates to its top N
        var result = map.mapValues { entries -> [String: WordStat] in
            guard entries.count > keepPerEntry else { return entries }
            let keep = Set(rank(entries, limit: keepPerEntry))
            return entries.filter { keep.contains($0.key) }
        }
        // Step 2: if still too many keys, drop the lowest-traffic ones
        if result.count > maxKeys {
            let sorted = result.sorted { a, b in
                a.value.values.reduce(0) { $0 + $1.count } >
                b.value.values.reduce(0) { $0 + $1.count }
            }
            result = Dictionary(uniqueKeysWithValues: sorted.prefix(maxKeys).map { ($0.key, $0.value) })
        }
        return result
    }
}
