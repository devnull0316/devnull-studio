import Foundation

/// Identifiers shared between the host app and the keyboard extension.
///
/// ⚠️ Replace `group.studio.devnull.predictivepersonas` with your own App Group
/// after you create it in the Apple Developer portal. The string MUST be
/// byte-for-byte identical in three places or the two processes will silently
/// read different containers:
///   - this file
///   - HostApp/HostApp.entitlements
///   - Keyboard/Keyboard.entitlements
enum AppGroup {
    static let identifier = "group.studio.devnull.predictivepersonas"

    /// Shared on-disk location for persona data, inside the App Group container.
    ///
    /// Both processes point `PersonaStore` here, so a persona created/edited in
    /// the app is visible to the keyboard (after a reload) and vice-versa.
    static var containerURL: URL {
        guard let base = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: identifier) else {
            // Fallback so the app still launches if the entitlement isn't wired
            // yet (e.g. first run in a fresh Simulator). Data just isn't shared
            // across processes in that case.
            return FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("PersonaData", isDirectory: true)
        }
        return base.appendingPathComponent("PersonaData", isDirectory: true)
    }
}
