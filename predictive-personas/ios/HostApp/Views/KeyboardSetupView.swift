import SwiftUI

/// How-to for enabling the custom keyboard, plus the privacy stance.
struct KeyboardSetupView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("キーボードを有効にする") {
                    Label("「設定」アプリを開く", systemImage: "1.circle")
                    Label("一般 → キーボード → キーボード", systemImage: "2.circle")
                    Label("「新しいキーボードを追加」→ Predictive Personas",
                          systemImage: "3.circle")
                    Label("任意のアプリで地球儀キーから切り替え", systemImage: "4.circle")
                }

                Section {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("設定アプリを開く", systemImage: "gear")
                    }
                }

                Section {
                    Text("Full Access はオフのままで動きます。学習データは端末内（App Group）にのみ保存され、外部には送信されません。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("設定")
        }
    }
}
