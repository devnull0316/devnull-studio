import Foundation

/// A shareable, versioned preset — the unit you **upload / download** in-app.
///
/// This is intentionally separate from the raw `Persona` on-device format:
///   - `exportPersona` / `importPersona`  → device backup/restore (keeps identity)
///   - `exportPackage`  / `importPackage`  → sharing a preset (always a fresh copy)
///
/// A `formatVersion` is baked in so that once presets are shared "in the wild"
/// (files, QR codes, a future server), the app can still read old packages and
/// reject ones that are too new to understand. Never reuse a version number for
/// an incompatible change — bump it.
public struct PersonaPackage: Codable, Equatable {
    /// The schema version this build writes and is the maximum it can read.
    public static let currentVersion = 1

    /// Schema version of *this* package (may be older than `currentVersion`).
    public var formatVersion: Int
    /// Name shown in the preset / share list (e.g. "zeta用", "日常用").
    public var displayName: String
    /// Optional human note describing the preset (e.g. "AIチャット用の語彙セット").
    public var note: String?
    /// When the package was exported (informational).
    public var exportedAt: Date
    /// The learned data being shared — the actual payload.
    public var store: LearningStore

    public init(formatVersion: Int = PersonaPackage.currentVersion,
                displayName: String,
                note: String? = nil,
                exportedAt: Date = Date(),
                store: LearningStore) {
        self.formatVersion = formatVersion
        self.displayName = displayName
        self.note = note
        self.exportedAt = exportedAt
        self.store = store
    }
}

public enum PersonaPackageError: Error, Equatable {
    /// The package was written by a newer app version than this one can read.
    case unsupportedVersion(Int)
}
