import XCTest
@testable import PersonaEngine

final class PersonaStoreTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_000_000)

    private func tempDir() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("persona-test-\(UUID().uuidString)")
    }

    func testSaveLoadRoundTrip() throws {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let engine = PersonaEngine()
        let a = engine.createPersona(name: "日常用", now: t0)
        try engine.learn(reading: "あ", surface: "朝", now: t0)
        let b = engine.createPersona(name: "仕事用", now: t0.addingTimeInterval(10))
        try engine.learn(reading: "かぶ", surface: "株式会社", now: t0.addingTimeInterval(10))
        try engine.switchPersona(to: a.id)

        let store = PersonaStore(directory: dir)
        try store.save(engine)

        let loaded = try store.load()
        XCTAssertEqual(loaded.personas.count, 2)
        XCTAssertEqual(loaded.activePersonaID, a.id)
        XCTAssertEqual(loaded.complete(reading: "あ"), ["朝"])   // active = 日常用
        try loaded.switchPersona(to: b.id)
        XCTAssertEqual(loaded.complete(reading: "かぶ"), ["株式会社"])
    }

    func testSavePrunesDeletedPersona() throws {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let engine = PersonaEngine()
        let a = engine.createPersona(name: "A", now: t0)
        let b = engine.createPersona(name: "B", now: t0.addingTimeInterval(1))
        let store = PersonaStore(directory: dir)
        try store.save(engine)

        engine.deletePersona(b.id)
        try store.save(engine)

        let loaded = try store.load()
        XCTAssertEqual(loaded.personas.count, 1)
        XCTAssertEqual(loaded.personas.first?.id, a.id)
    }

    func testLoadFromEmptyDirectory() throws {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let loaded = try PersonaStore(directory: dir).load()
        XCTAssertTrue(loaded.personas.isEmpty)
        XCTAssertNil(loaded.activePersonaID)
    }
}
