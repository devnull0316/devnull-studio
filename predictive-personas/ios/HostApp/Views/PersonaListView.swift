import SwiftUI
import PersonaEngine

/// The core product UI: a list of persona layers you can switch between, create,
/// and delete. The checkmark marks the active one — its learning data is what
/// the keyboard uses for predictions.
struct PersonaListView: View {
    @EnvironmentObject private var model: PersonaViewModel
    @State private var showingNew = false
    @State private var newName = ""
    @State private var seedLexicon = true

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(model.personas) { persona in
                        Button {
                            model.switchPersona(to: persona.id)
                        } label: {
                            row(for: persona)
                        }
                        .foregroundStyle(.primary)
                    }
                    .onDelete { offsets in
                        offsets.map { model.personas[$0].id }.forEach(model.deletePersona)
                    }
                } header: {
                    Text("タップで切り替え")
                } footer: {
                    Text("アクティブなペルソナの学習データだけが、キーボードの予測変換に使われます。")
                }
            }
            .navigationTitle("ペルソナ")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNew = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingNew) { newPersonaSheet }
            .refreshable { model.refresh() }
        }
    }

    private func row(for persona: Persona) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(persona.name).font(.body)
                Text("\(persona.store.completions.count) よみを学習済み")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if persona.id == model.activeID {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
            }
        }
    }

    private var newPersonaSheet: some View {
        NavigationStack {
            Form {
                TextField("名前（例：zeta用、仕事用）", text: $newName)
                Toggle("基本辞書をシードする", isOn: $seedLexicon)
            }
            .navigationTitle("新しいペルソナ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { reset() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("作成") {
                        let name = newName.trimmingCharacters(in: .whitespaces)
                        guard !name.isEmpty else { return }
                        model.createPersona(name: name, seedLexicon: seedLexicon)
                        reset()
                    }
                }
            }
        }
    }

    private func reset() {
        newName = ""
        seedLexicon = true
        showingNew = false
    }
}
