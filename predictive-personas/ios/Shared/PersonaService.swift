import Foundation
import PersonaEngine

/// Persistence-aware wrapper around `PersonaEngine`, shared by the host app and
/// the keyboard extension.
///
/// Both processes talk to the *same* App Group directory through `PersonaStore`,
/// so a persona created in the app becomes usable in the keyboard after a
/// `reload()`. There is no live cross-process push: each side re-reads from disk
/// at natural moments (app foreground, keyboard appearance). Good enough for the
/// PoC; CloudKit/observers come later (see docs/ARCHITECTURE.md).
final class PersonaService {
    let store: PersonaStore
    private(set) var engine: PersonaEngine

    init(directory: URL = AppGroup.containerURL) {
        self.store = PersonaStore(directory: directory)
        self.engine = (try? store.load()) ?? PersonaEngine()
    }

    /// Re-read from disk (call when the other process may have changed things).
    func reload() {
        engine = (try? store.load()) ?? PersonaEngine()
    }

    /// Persist current state. Best-effort; the caller decides how to surface errors.
    func persist() throws {
        try store.save(engine)
    }

    /// First-run convenience: if there are no personas yet, create a default one
    /// seeded with the built-in lexicon so the keyboard is never empty.
    /// Returns `true` if it actually created the default persona.
    @discardableResult
    func bootstrapIfEmpty() -> Bool {
        guard engine.personas.isEmpty else { return false }
        engine.createPersona(name: "日常用")
        try? engine.seedDefaultLexicon()
        try? persist()
        return true
    }
}
