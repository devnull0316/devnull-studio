import Foundation

public enum PersonaError: Error, Equatable {
    case noActivePersona
    case personaNotFound(UUID)
}

/// Cross-platform predictive-text engine with switchable persona layers.
///
/// Foundation-only (no UIKit) so it builds & tests on Windows/Linux and is
/// later imported by the iOS keyboard extension unchanged. All learning and
/// prediction operate on the *active* persona only.
public final class PersonaEngine {
    public private(set) var personas: [Persona]
    public private(set) var activePersonaID: UUID?

    /// Decay half-life for recency ranking.
    /// - `nil` (default): rank by raw count, then recency, then lex — backward-compatible.
    /// - Any positive interval: older high-count words can be beaten by fresher words.
    ///   30 days (`30 * 86_400`) is a sensible production default.
    public var halfLife: TimeInterval?

    public init(personas: [Persona] = [], activePersonaID: UUID? = nil,
                halfLife: TimeInterval? = nil) {
        self.personas = personas
        self.activePersonaID = activePersonaID ?? personas.first?.id
        self.halfLife = halfLife
    }

    public var activePersona: Persona? {
        guard let id = activePersonaID else { return nil }
        return personas.first { $0.id == id }
    }

    // MARK: - Persona management

    @discardableResult
    public func createPersona(name: String, activate: Bool = true, now: Date = Date()) -> Persona {
        let persona = Persona(name: name, createdAt: now)
        personas.append(persona)
        if activate || activePersonaID == nil { activePersonaID = persona.id }
        return persona
    }

    public func switchPersona(to id: UUID) throws {
        guard personas.contains(where: { $0.id == id }) else { throw PersonaError.personaNotFound(id) }
        activePersonaID = id
    }

    public func deletePersona(_ id: UUID) {
        personas.removeAll { $0.id == id }
        if activePersonaID == id { activePersonaID = personas.first?.id }
    }

    // MARK: - Learning & prediction (active persona)

    /// Learn that the user typed `surface` (read as `reading`).
    ///
    /// `reading` accepts either hiragana or romaji — romaji is automatically
    /// converted to hiragana so that `complete("suki")` finds what was learned
    /// with `learn(reading: "すき", ...)` and vice-versa.
    public func learn(reading: String, surface: String, previous: String? = nil, now: Date = Date()) throws {
        let normalizedReading = RomajiConverter.resolvedHiragana(reading)
        let key = normalizedReading.isEmpty ? reading : normalizedReading
        try mutateActive {
            $0.store.learn(reading: key, surface: surface, previous: previous, at: now)
            $0.updatedAt = now
        }
    }

    /// Candidate completions for the given reading prefix.
    ///
    /// `reading` accepts romaji — only the definitively-converted hiragana portion
    /// is used for lookup, so partial input like `"suk"` searches on `"す"`.
    /// When `halfLife` is set on this engine, recency decay is applied.
    public func complete(reading: String, limit: Int = 5, now: Date = Date()) -> [String] {
        let hiragana = RomajiConverter.resolvedHiragana(reading)
        let key = hiragana.isEmpty ? reading : hiragana
        return activePersona?.store.candidates(
            forReading: key, limit: limit,
            now: halfLife != nil ? now : nil,
            halfLife: halfLife ?? 30 * 86_400
        ) ?? []
    }

    /// Likely next words after `surface`, best first.
    public func predictNext(after surface: String, limit: Int = 5, now: Date = Date()) -> [String] {
        activePersona?.store.candidates(
            after: surface, limit: limit,
            now: halfLife != nil ? now : nil,
            halfLife: halfLife ?? 30 * 86_400
        ) ?? []
    }

    // MARK: - Default lexicon

    /// Seed the active persona with a small built-in vocabulary so that common
    /// words appear as candidates for a brand-new user.
    ///
    /// Each entry is recorded at `Date.distantPast`, guaranteeing it always
    /// ranks below anything the user has actually typed.
    public func seedDefaultLexicon() throws {
        for (reading, surface) in DefaultLexicon.entries {
            try learn(reading: reading, surface: surface, now: .distantPast)
        }
    }

    // MARK: - Pruning

    /// Trim the active persona's learning store to stay within memory bounds.
    public func pruneActivePersona(keepPerReading: Int = 20, maxReadings: Int = 500) throws {
        try mutateActive { $0.store.prune(keepPerReading: keepPerReading, maxReadings: maxReadings) }
    }

    // MARK: - Portability (= upload / download / carry)

    /// Serialize one persona to JSON — the file you'd upload to a named set.
    public func exportPersona(_ id: UUID) throws -> Data {
        guard let persona = personas.first(where: { $0.id == id }) else {
            throw PersonaError.personaNotFound(id)
        }
        return try Self.encoder.encode(persona)
    }

    /// Load a persona from JSON — the file you'd download to use here.
    /// If the id already exists on this device, a fresh id is assigned so the
    /// import never clobbers an existing persona.
    @discardableResult
    public func importPersona(from data: Data, activate: Bool = false) throws -> Persona {
        let decoded = try Self.decoder.decode(Persona.self, from: data)
        let persona: Persona
        if personas.contains(where: { $0.id == decoded.id }) {
            persona = Persona(name: decoded.name,
                              createdAt: decoded.createdAt,
                              updatedAt: decoded.updatedAt,
                              store: decoded.store)
        } else {
            persona = decoded
        }
        personas.append(persona)
        if activate { activePersonaID = persona.id }
        return persona
    }

    // MARK: - Shareable presets (= in-app upload / download)

    /// Export one persona as a shareable, versioned preset package.
    ///
    /// This is the byte payload the app would **upload** (to a file, QR code,
    /// or a future preset server). Unlike `exportPersona`, it carries a format
    /// version and display metadata and omits device-specific identity.
    public func exportPackage(_ id: UUID, note: String? = nil, now: Date = Date()) throws -> Data {
        guard let persona = personas.first(where: { $0.id == id }) else {
            throw PersonaError.personaNotFound(id)
        }
        let package = PersonaPackage(displayName: persona.name,
                                     note: note,
                                     exportedAt: now,
                                     store: persona.store)
        return try Self.encoder.encode(package)
    }

    /// Import a shared preset package — what the app does on **download**.
    ///
    /// Sharing is always a *copy*: the imported preset becomes a brand-new
    /// persona with a fresh identity, so downloading never clobbers or aliases
    /// an existing persona. Rejects packages from a newer, unsupported format.
    @discardableResult
    public func importPackage(from data: Data, activate: Bool = false, now: Date = Date()) throws -> Persona {
        let package = try Self.decoder.decode(PersonaPackage.self, from: data)
        guard package.formatVersion <= PersonaPackage.currentVersion else {
            throw PersonaPackageError.unsupportedVersion(package.formatVersion)
        }
        let persona = Persona(name: package.displayName,
                              createdAt: now,
                              updatedAt: now,
                              store: package.store)
        personas.append(persona)
        if activate { activePersonaID = persona.id }
        return persona
    }

    // MARK: - Helpers

    private func mutateActive(_ body: (inout Persona) -> Void) throws {
        guard let id = activePersonaID, let idx = personas.firstIndex(where: { $0.id == id }) else {
            throw PersonaError.noActivePersona
        }
        body(&personas[idx])
    }

    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
