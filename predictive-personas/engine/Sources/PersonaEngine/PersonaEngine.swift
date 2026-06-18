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

    public init(personas: [Persona] = [], activePersonaID: UUID? = nil) {
        self.personas = personas
        self.activePersonaID = activePersonaID ?? personas.first?.id
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

    public func learn(reading: String, surface: String, previous: String? = nil, now: Date = Date()) throws {
        try mutateActive {
            $0.store.learn(reading: reading, surface: surface, previous: previous, at: now)
            $0.updatedAt = now
        }
    }

    public func complete(reading: String, limit: Int = 5) -> [String] {
        activePersona?.store.candidates(forReading: reading, limit: limit) ?? []
    }

    public func predictNext(after surface: String, limit: Int = 5) -> [String] {
        activePersona?.store.candidates(after: surface, limit: limit) ?? []
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
