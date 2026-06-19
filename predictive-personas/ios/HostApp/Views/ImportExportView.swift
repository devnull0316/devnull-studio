import SwiftUI

/// In-app upload / download of preset packages.
///   - Upload : export the active persona as a `.personapack.json` and share it.
///   - Download: import a package from Files as a new persona.
///
/// This is the UI on top of `exportPackage` / `importPackage` in the engine.
struct ImportExportView: View {
    @EnvironmentObject private var model: PersonaViewModel
    @State private var note = ""
    @State private var exportURL: URL?
    @State private var importing = false

    var body: some View {
        NavigationStack {
            Form {
                Section("アップロード（プリセットを書き出す）") {
                    if let active = model.activePersona {
                        LabeledContent("対象", value: active.name)
                        TextField("メモ（任意）", text: $note)
                        Button("プリセットを書き出す") {
                            exportURL = model.exportPackage(
                                active.id, note: note.isEmpty ? nil : note)
                        }
                        if let url = exportURL {
                            ShareLink(item: url) {
                                Label("共有シートを開く", systemImage: "square.and.arrow.up")
                            }
                        }
                    } else {
                        Text("アクティブなペルソナがありません")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button {
                        importing = true
                    } label: {
                        Label("ファイルからプリセットを読み込む",
                              systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("ダウンロード（プリセットを読み込む）")
                } footer: {
                    Text("読み込んだプリセットは常に新しいペルソナとして追加され、既存のものを上書きしません。")
                }
            }
            .navigationTitle("共有")
            .fileImporter(isPresented: $importing,
                          allowedContentTypes: [.json],
                          allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    if let first = urls.first { model.importPackage(from: first) }
                case .failure(let error):
                    model.errorMessage = error.localizedDescription
                }
            }
            .alert("エラー", isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(model.errorMessage ?? "")
            }
        }
    }
}
