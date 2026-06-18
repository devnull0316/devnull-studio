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
}
