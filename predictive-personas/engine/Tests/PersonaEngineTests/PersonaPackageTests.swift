import XCTest
@testable import PersonaEngine

final class PersonaPackageTests: XCTestCase {
    /// Fixed whole-second timestamp so JSON (.iso8601) round-trips exactly.
    private let t0 = Date(timeIntervalSince1970: 1_000_000)

    // MARK: - Round trip (upload → download)

    func testPackageRoundTripCarriesLearning() throws {
        let engine = PersonaEngine()
        let p = engine.createPersona(name: "zeta用", now: t0)
        try engine.learn(reading: "すき", surface: "好きかもしれない", now: t0)

        // "upload": export as a shareable preset
        let packet = try engine.exportPackage(p.id, note: "AIチャット用語彙", now: t0)

        // "download" on another device
        let other = PersonaEngine()
        let imported = try other.importPackage(from: packet, activate: true, now: t0)

        XCTAssertEqual(imported.name, "zeta用")
        XCTAssertEqual(other.complete(reading: "すき"), ["好きかもしれない"])
        XCTAssertEqual(other.activePersonaID, imported.id)
    }

    func testPackagePreservesDisplayNameAndNote() throws {
        let engine = PersonaEngine()
        let p = engine.createPersona(name: "仕事用", now: t0)
        let data = try engine.exportPackage(p.id, note: "敬語セット", now: t0)

        let pkg = try PersonaEngine.decoder.decode(PersonaPackage.self, from: data)
        XCTAssertEqual(pkg.displayName, "仕事用")
        XCTAssertEqual(pkg.note, "敬語セット")
        XCTAssertEqual(pkg.formatVersion, PersonaPackage.currentVersion)
    }

    // MARK: - Download is always a fresh copy

    func testImportPackageAlwaysCreatesNewIdentity() throws {
        let engine = PersonaEngine()
        let p = engine.createPersona(name: "dup", now: t0)
        let data = try engine.exportPackage(p.id, now: t0)

        // Re-importing into the *same* engine must not alias the original.
        let imported = try engine.importPackage(from: data, now: t0)
        XCTAssertNotEqual(imported.id, p.id)
        XCTAssertEqual(engine.personas.count, 2)
    }

    // MARK: - Version gate

    func testImportRejectsNewerFormat() throws {
        let future = PersonaPackage(formatVersion: PersonaPackage.currentVersion + 1,
                                    displayName: "未来",
                                    exportedAt: t0,
                                    store: LearningStore())
        let data = try PersonaEngine.encoder.encode(future)

        let engine = PersonaEngine()
        XCTAssertThrowsError(try engine.importPackage(from: data)) {
            XCTAssertEqual($0 as? PersonaPackageError,
                           .unsupportedVersion(PersonaPackage.currentVersion + 1))
        }
    }

    func testExportUnknownPersonaThrows() {
        let engine = PersonaEngine()
        let unknown = UUID()
        XCTAssertThrowsError(try engine.exportPackage(unknown)) {
            XCTAssertEqual($0 as? PersonaError, .personaNotFound(unknown))
        }
    }
}
