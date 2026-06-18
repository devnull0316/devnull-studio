import Foundation

/// A named, switchable "persona layer" — e.g. "zeta用", "日常用", "仕事用".
///
/// Each persona owns its isolated `LearningStore`, so personas can be
/// attached/detached, exported and imported independently. This is the core
/// product idea: predictive text you can switch and carry, like changing skins.
public struct Persona: Codable, Identifiable, Equatable {
    public let id: UUID
    public var name: String
    public let createdAt: Date
    public var updatedAt: Date
    public var store: LearningStore

    public init(id: UUID = UUID(),
                name: String,
                createdAt: Date = Date(),
                updatedAt: Date? = nil,
                store: LearningStore = LearningStore()) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
        self.store = store
    }
}
