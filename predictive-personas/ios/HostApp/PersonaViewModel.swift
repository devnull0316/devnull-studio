import Foundation
import PersonaEngine

/// Observable bridge between SwiftUI and the shared `PersonaService`.
///
/// Every mutation persists immediately and then re-reads, so the published
/// snapshot always matches what's on disk (and therefore what the keyboard
/// extension will load).
@MainActor
final class PersonaViewModel: ObservableObject {
    private let service = PersonaService()

    @Published private(set) var personas: [Persona] = []
    @Published private(set) var activeID: UUID?
    @Published var errorMessage: String?

    init() {
        service.bootstrapIfEmpty()
        refresh()
    }

    func refresh() {
        service.reload()
        personas = service.engine.personas
        activeID = service.engine.activePersonaID
    }

    var activePersona: Persona? {
        personas.first { $0.id == activeID }
    }

    // MARK: - Mutations

    func createPersona(name: String, seedLexicon: Bool) {
        service.engine.createPersona(name: name)
        if seedLexicon { try? service.engine.seedDefaultLexicon() }
        save()
    }

    func switchPersona(to id: UUID) {
        try? service.engine.switchPersona(to: id)
        save()
    }

    func deletePersona(_ id: UUID) {
        service.engine.deletePersona(id)
        save()
    }

    // MARK: - Upload / download (preset packages)

    /// "Upload": write the persona as a shareable preset package to a temp file
    /// and return its URL for a share sheet.
    func exportPackage(_ id: UUID, note: String?) -> URL? {
        do {
            let data = try service.engine.exportPackage(id, note: note)
            let name = personas.first { $0.id == id }?.name ?? "persona"
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(name).personapack.json")
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            errorMessage = "書き出しに失敗しました：\(error.localizedDescription)"
            return nil
        }
    }

    /// "Download": import a preset package picked from Files. Always added as a
    /// brand-new persona (never overwrites an existing one).
    func importPackage(from url: URL) {
        do {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            _ = try service.engine.importPackage(from: data, activate: true)
            save()
        } catch {
            errorMessage = "読み込みに失敗しました：\(error.localizedDescription)"
        }
    }

    // MARK: - Private

    private func save() {
        do { try service.persist() }
        catch { errorMessage = "保存に失敗しました：\(error.localizedDescription)" }
        refresh()
    }
}
