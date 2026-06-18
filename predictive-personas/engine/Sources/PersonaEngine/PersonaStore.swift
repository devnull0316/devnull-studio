import Foundation

/// Disk persistence for the whole engine state. Cross-platform (FileManager).
///
/// On iOS this `directory` will live in the **App Group container** so the
/// container app (where you manage personas) and the keyboard extension
/// (where you type) share the exact same data.
public struct PersonaStore {
    public let directory: URL
    private var personasDir: URL { directory.appendingPathComponent("personas", isDirectory: true) }
    private var stateFile: URL { directory.appendingPathComponent("state.json") }

    public init(directory: URL) {
        self.directory = directory
    }

    private struct State: Codable { var activePersonaID: UUID? }

    public func save(_ engine: PersonaEngine) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: personasDir, withIntermediateDirectories: true)

        // Write each persona as its own JSON file.
        for persona in engine.personas {
            let url = personasDir.appendingPathComponent("\(persona.id.uuidString).json")
            try PersonaEngine.encoder.encode(persona).write(to: url, options: .atomic)
        }

        // Prune files for personas that were deleted.
        let valid = Set(engine.personas.map { "\($0.id.uuidString).json" })
        if let existing = try? fm.contentsOfDirectory(atPath: personasDir.path) {
            for file in existing where file.hasSuffix(".json") && !valid.contains(file) {
                try? fm.removeItem(at: personasDir.appendingPathComponent(file))
            }
        }

        let state = State(activePersonaID: engine.activePersonaID)
        try PersonaEngine.encoder.encode(state).write(to: stateFile, options: .atomic)
    }

    public func load() throws -> PersonaEngine {
        let fm = FileManager.default
        guard fm.fileExists(atPath: personasDir.path) else { return PersonaEngine() }

        var personas: [Persona] = []
        let files = (try? fm.contentsOfDirectory(atPath: personasDir.path)) ?? []
        for file in files where file.hasSuffix(".json") {
            let url = personasDir.appendingPathComponent(file)
            let data = try Data(contentsOf: url)
            personas.append(try PersonaEngine.decoder.decode(Persona.self, from: data))
        }
        personas.sort { $0.createdAt < $1.createdAt }

        var activeID: UUID?
        if let data = try? Data(contentsOf: stateFile),
           let state = try? PersonaEngine.decoder.decode(State.self, from: data) {
            activeID = state.activePersonaID
        }
        return PersonaEngine(personas: personas, activePersonaID: activeID)
    }
}
