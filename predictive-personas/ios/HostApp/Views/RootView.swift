import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            PersonaListView()
                .tabItem { Label("ペルソナ", systemImage: "person.2.crop.square.stack") }
            ImportExportView()
                .tabItem { Label("共有", systemImage: "square.and.arrow.up.on.square") }
            KeyboardSetupView()
                .tabItem { Label("設定", systemImage: "keyboard") }
        }
    }
}
