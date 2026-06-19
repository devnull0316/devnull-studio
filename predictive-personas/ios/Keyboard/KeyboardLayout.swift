import Foundation

enum KeyboardLayout {
    /// Romaji QWERTY rows. Typing romaji keeps the keyboard tiny while
    /// `PersonaEngine` / `RomajiConverter` do the kana conversion — the heavy
    /// lifting lives in the engine, not in this view.
    static let letterRows: [[Character]] = [
        Array("qwertyuiop"),
        Array("asdfghjkl"),
        Array("zxcvbnm"),
    ]
}
