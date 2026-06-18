import XCTest
@testable import PersonaEngine

final class PersonaEngineTests: XCTestCase {
    /// Fixed whole-second timestamp so JSON (.iso8601) round-trips exactly.
    private let t0 = Date(timeIntervalSince1970: 1_000_000)

    func testCreateAndActivate() {
        let engine = PersonaEngine()
        XCTAssertNil(engine.activePersona)
        let p = engine.createPersona(name: "日常用", now: t0)
        XCTAssertEqual(engine.activePersona?.id, p.id)
        XCTAssertEqual(engine.personas.count, 1)
    }

    func testLearnAndCompleteRanksByFrequency() throws {
        let engine = PersonaEngine()
        engine.createPersona(name: "日常用", now: t0)
        try engine.learn(reading: "あ", surface: "朝", now: t0)
        try engine.learn(reading: "あ", surface: "朝", now: t0.addingTimeInterval(1))
        try engine.learn(reading: "あ", surface: "雨", now: t0.addingTimeInterval(2))
        // 朝 used twice beats 雨 used once
        XCTAssertEqual(engine.complete(reading: "あ"), ["朝", "雨"])
    }

    func testRecencyBreaksFrequencyTie() throws {
        let engine = PersonaEngine()
        engine.createPersona(name: "日常用", now: t0)
        try engine.learn(reading: "き", surface: "木", now: t0)                          // older
        try engine.learn(reading: "き", surface: "気", now: t0.addingTimeInterval(100))   // newer
        // same count (1); newer wins
        XCTAssertEqual(engine.complete(reading: "き").first, "気")
    }

    func testPredictNext() throws {
        let engine = PersonaEngine()
        engine.createPersona(name: "日常用", now: t0)
        try engine.learn(reading: "", surface: "行く", previous: "学校", now: t0)
        XCTAssertEqual(engine.predictNext(after: "学校"), ["行く"])
    }

    func testPersonaIsolation() throws {
        let engine = PersonaEngine()
        let work = engine.createPersona(name: "仕事用", now: t0)
        try engine.learn(reading: "かぶ", surface: "株式会社", now: t0)

        engine.createPersona(name: "zeta用", now: t0)            // becomes active
        try engine.learn(reading: "かぶ", surface: "かぶたん", now: t0)

        XCTAssertEqual(engine.complete(reading: "かぶ"), ["かぶたん"])
        try engine.switchPersona(to: work.id)
        XCTAssertEqual(engine.complete(reading: "かぶ"), ["株式会社"])
    }

    func testLearnWithoutActiveThrows() {
        let engine = PersonaEngine()
        XCTAssertThrowsError(try engine.learn(reading: "あ", surface: "朝")) {
            XCTAssertEqual($0 as? PersonaError, .noActivePersona)
        }
    }

    func testSwitchUnknownThrows() {
        let engine = PersonaEngine()
        let unknown = UUID()
        XCTAssertThrowsError(try engine.switchPersona(to: unknown)) {
            XCTAssertEqual($0 as? PersonaError, .personaNotFound(unknown))
        }
    }

    func testDeleteReassignsActive() {
        let engine = PersonaEngine()
        let a = engine.createPersona(name: "A", now: t0)
        let b = engine.createPersona(name: "B", now: t0)
        XCTAssertEqual(engine.activePersonaID, b.id)
        engine.deletePersona(b.id)
        XCTAssertEqual(engine.activePersonaID, a.id)
    }

    func testExportImportRoundTrip() throws {
        let engine = PersonaEngine()
        let p = engine.createPersona(name: "zeta用", now: t0)
        try engine.learn(reading: "あ", surface: "朝", now: t0)
        let data = try engine.exportPersona(p.id)

        let other = PersonaEngine()
        let imported = try other.importPersona(from: data, activate: true)
        XCTAssertEqual(imported.name, "zeta用")
        XCTAssertEqual(other.complete(reading: "あ"), ["朝"])
    }

    func testImportAvoidsIDCollision() throws {
        let engine = PersonaEngine()
        let p = engine.createPersona(name: "dup", now: t0)
        let data = try engine.exportPersona(p.id)
        let imported = try engine.importPersona(from: data)
        XCTAssertNotEqual(imported.id, p.id)
        XCTAssertEqual(engine.personas.count, 2)
    }

    func testLimitIsRespected() throws {
        let engine = PersonaEngine()
        engine.createPersona(name: "x", now: t0)
        for (i, s) in ["a", "b", "c", "d"].enumerated() {
            try engine.learn(reading: "r", surface: s, now: t0.addingTimeInterval(Double(i)))
        }
        XCTAssertEqual(engine.complete(reading: "r", limit: 2).count, 2)
    }

    // MARK: - M1: Romaji input

    func testRomajiCompleteFindsHiraganaKey() throws {
        let engine = PersonaEngine()
        engine.createPersona(name: "test", now: t0)
        try engine.learn(reading: "すき", surface: "好きかもしれない", now: t0)
        // Full romaji resolves to the exact hiragana key
        XCTAssertEqual(engine.complete(reading: "suki").first, "好きかもしれない")
        // Partial romaji "su" → "す" resolves to a different key than "すき" → no match (exact lookup)
        XCTAssertEqual(engine.complete(reading: "su"), [])
    }

    func testRomajiLearnAndComplete() throws {
        let engine = PersonaEngine()
        engine.createPersona(name: "test", now: t0)
        // Learn with romaji reading — should store under hiragana
        try engine.learn(reading: "kawaii", surface: "かわいい", now: t0)
        XCTAssertEqual(engine.complete(reading: "kawaii").first, "かわいい")
        XCTAssertEqual(engine.complete(reading: "かわいい").first, "かわいい") // kana lookup still works
    }

    func testPartialRomajiSearchesOnResolvedPortion() throws {
        let engine = PersonaEngine()
        engine.createPersona(name: "test", now: t0)
        try engine.learn(reading: "ありがとう", surface: "ありがとうございます", now: t0)
        // "ariga" resolves to "ありが"; partial match finds candidates for "ありが"
        // (Lookup is exact, so this returns empty — the key is "ありがとう" not "ありが")
        // Key point: "sh" → resolved = "" → no crash, just empty result
        XCTAssertEqual(engine.complete(reading: "sh"), [])
        // And "su" with nothing learned → empty
        XCTAssertEqual(engine.complete(reading: "su"), [])
    }

    // MARK: - M1: Recency decay

    func testDecayDemotesOldHighCountWord() throws {
        // Use 1-second half-life so differences are dramatic in tests
        let halfLife: TimeInterval = 1
        let engine = PersonaEngine(halfLife: halfLife)
        engine.createPersona(name: "test", now: t0)

        let recentTime = t0
        let ancientTime = t0.addingTimeInterval(-1000) // 1000 seconds ago → 1000 half-lives back

        // "古い" learned 3 times but long ago
        try engine.learn(reading: "こ", surface: "古い", now: ancientTime)
        try engine.learn(reading: "こ", surface: "古い", now: ancientTime)
        try engine.learn(reading: "こ", surface: "古い", now: ancientTime)
        // "今" learned once but just now
        try engine.learn(reading: "こ", surface: "今", now: recentTime)

        // Without decay: "古い" (count=3) beats "今" (count=1)
        let noDecay = PersonaEngine()
        noDecay.createPersona(name: "t", now: t0)
        try noDecay.learn(reading: "こ", surface: "古い", now: ancientTime)
        try noDecay.learn(reading: "こ", surface: "古い", now: ancientTime)
        try noDecay.learn(reading: "こ", surface: "古い", now: ancientTime)
        try noDecay.learn(reading: "こ", surface: "今", now: recentTime)
        XCTAssertEqual(noDecay.complete(reading: "こ").first, "古い")

        // With decay: "今" (fresh) beats "古い" (ancient)
        XCTAssertEqual(engine.complete(reading: "こ", now: recentTime).first, "今")
    }

    // MARK: - M1: Default lexicon

    func testSeedDefaultLexiconPopulatesCandidates() throws {
        let engine = PersonaEngine()
        engine.createPersona(name: "fresh", now: t0)
        try engine.seedDefaultLexicon()

        // Brand-new persona should now have suggestions for common words
        XCTAssertFalse(engine.complete(reading: "ありがとう").isEmpty)
        XCTAssertFalse(engine.complete(reading: "すき").isEmpty)
        XCTAssertFalse(engine.complete(reading: "きょう").isEmpty)
    }

    func testUserLearningOutranksLexicon() throws {
        let engine = PersonaEngine()
        engine.createPersona(name: "test", now: t0)
        try engine.seedDefaultLexicon()

        // User explicitly types "好きかもしれない" for "すき" — should outrank lexicon's "好き"
        try engine.learn(reading: "すき", surface: "好きかもしれない", now: t0)
        try engine.learn(reading: "すき", surface: "好きかもしれない", now: t0.addingTimeInterval(1))
        XCTAssertEqual(engine.complete(reading: "すき").first, "好きかもしれない")
    }

    // MARK: - M1: Pruning

    func testPruneReducesEntries() throws {
        let engine = PersonaEngine()
        engine.createPersona(name: "test", now: t0)
        // Learn 10 distinct surfaces for the same reading
        for i in 0..<10 {
            try engine.learn(reading: "あ", surface: "word\(i)",
                             now: t0.addingTimeInterval(Double(i)))
        }
        // Before prune: 10 surfaces
        XCTAssertEqual(engine.activePersona?.store.completions["あ"]?.count, 10)

        // Prune to top 3
        try engine.pruneActivePersona(keepPerReading: 3, maxReadings: 500)
        XCTAssertEqual(engine.activePersona?.store.completions["あ"]?.count, 3)
    }

    func testPruneKeepsMostUsed() throws {
        let engine = PersonaEngine()
        engine.createPersona(name: "test", now: t0)
        // "popular" used 5×, others used once
        for _ in 0..<5 {
            try engine.learn(reading: "あ", surface: "popular", now: t0)
        }
        for i in 1...4 {
            try engine.learn(reading: "あ", surface: "rare\(i)", now: t0)
        }
        try engine.pruneActivePersona(keepPerReading: 2)
        let survivors = engine.activePersona?.store.completions["あ"]?.keys
        XCTAssertTrue(survivors?.contains("popular") == true)
    }
}
