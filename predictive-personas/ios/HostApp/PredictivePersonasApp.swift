import SwiftUI

@main
struct PredictivePersonasApp: App {
    @StateObject private var model = PersonaViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
        }
        .onChange(of: scenePhase) { _, phase in
            // Re-read on foreground in case the keyboard changed the active
            // persona while the app was backgrounded.
            if phase == .active { model.refresh() }
        }
    }
}
