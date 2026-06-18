import Foundation
import PersonaEngine

// Run on Windows or Linux today:  swift run persona-demo
// Shows both the original product thesis (M0) and M1 engine enhancements.

func show(_ title: String) { print("\n=== \(title) ===") }

// ─────────────────────────────────────────────
//  M0: Core product thesis (persona switching)
// ─────────────────────────────────────────────
let engine = PersonaEngine()

show("1) Create two persona layers")
let daily = engine.createPersona(name: "日常用")
let zeta  = engine.createPersona(name: "zeta用")   // becomes active
print("personas:", engine.personas.map(\.name))
print("active  :", engine.activePersona?.name ?? "-")

show("2) Teach the zeta persona some private vocabulary")
try engine.learn(reading: "すき", surface: "好きかもしれない")
try engine.learn(reading: "すき", surface: "好きかもしれない")
try engine.learn(reading: "あい", surface: "アイ（推し）")
print("zeta  すき →", engine.complete(reading: "すき"))

show("3) Switch to the daily persona and teach different words")
try engine.switchPersona(to: daily.id)
try engine.learn(reading: "すき", surface: "スキー")
try engine.learn(reading: "あい", surface: "会議")
print("daily すき →", engine.complete(reading: "すき"))
print("active     :", engine.activePersona?.name ?? "-")

show("4) The two layers are isolated — same reading, different worlds")
try engine.switchPersona(to: zeta.id)
print("zeta  すき →", engine.complete(reading: "すき"))
try engine.switchPersona(to: daily.id)
print("daily すき →", engine.complete(reading: "すき"))

show("5) Carry a persona: export to JSON, import on another 'device'")
let packet = try engine.exportPersona(zeta.id)
print("exported zeta packet: \(packet.count) bytes")
let otherDevice = PersonaEngine()
let restored = try otherDevice.importPersona(from: packet, activate: true)
print("imported on new device:", restored.name)
print("new device すき →", otherDevice.complete(reading: "すき"))

// ─────────────────────────────────────────────
//  M1: Engine enhancements
// ─────────────────────────────────────────────

show("6) M1 — Romaji input  (type 'suki', find 'すき' candidates)")
// Users can type romaji; the engine converts to hiragana internally
let romajiEngine = PersonaEngine()
romajiEngine.createPersona(name: "test")
try romajiEngine.learn(reading: "すき", surface: "好きかもしれない")
try romajiEngine.learn(reading: "すき", surface: "好きかもしれない")
print("complete('suki')  →", romajiEngine.complete(reading: "suki"))   // romaji → finds hiragana key
print("complete('su')    →", romajiEngine.complete(reading: "su"))     // partial → searches on 'す'
print("complete('sh')    →", romajiEngine.complete(reading: "sh"))     // unresolved → [] (no crash)

let conv = RomajiConverter.convert("suk")
print("convert('suk')    → hiragana='\(conv.hiragana)' pending='\(conv.pending)'")

show("7) M1 — Default lexicon  (suggestions on day 1, before any learning)")
let freshEngine = PersonaEngine()
freshEngine.createPersona(name: "新規ユーザー")
try freshEngine.seedDefaultLexicon()
print("ありがとう →", freshEngine.complete(reading: "ありがとう"))
print("すき       →", freshEngine.complete(reading: "すき"))
print("きょう     →", freshEngine.complete(reading: "きょう"))

// User typing beats the lexicon seed automatically
try freshEngine.learn(reading: "すき", surface: "好きかもしれない")
try freshEngine.learn(reading: "すき", surface: "好きかもしれない")
print("after 2× user input すき →", freshEngine.complete(reading: "すき"))

show("8) M1 — Recency decay  (stale words demoted even if high count)")
// Half-life of 30 days means words unused for months gradually lose rank.
// Demo uses 1-second half-life to make the effect visible immediately.
let decayEngine = PersonaEngine(halfLife: 1)
decayEngine.createPersona(name: "decay-test")
let ancient = Date(timeIntervalSince1970: 0)   // 1970: long gone
let recent  = Date()
try decayEngine.learn(reading: "こ", surface: "古い単語", now: ancient)
try decayEngine.learn(reading: "こ", surface: "古い単語", now: ancient)
try decayEngine.learn(reading: "こ", surface: "古い単語", now: ancient)  // count=3 but ancient
try decayEngine.learn(reading: "こ", surface: "新しい単語", now: recent)              // count=1 but fresh
print("no decay : '古い単語'(×3) vs '新しい単語'(×1) → 古い単語 wins on count")
print("with decay (1s half-life) →", decayEngine.complete(reading: "こ", now: recent))

show("9) M1 — Pruning  (cap memory for long-running personas)")
let pruneEngine = PersonaEngine()
pruneEngine.createPersona(name: "prune-test")
for i in 0..<15 {
    try pruneEngine.learn(reading: "あ", surface: "語\(i)", now: Date(timeIntervalSince1970: Double(i)))
}
print("before prune: \(pruneEngine.activePersona!.store.completions["あ"]!.count) surfaces for 'あ'")
try pruneEngine.pruneActivePersona(keepPerReading: 5)
print("after  prune: \(pruneEngine.activePersona!.store.completions["あ"]!.count) surfaces for 'あ'")
print("top 5 kept  :", pruneEngine.complete(reading: "あ", limit: 5))

show("10) In-app upload / download / preset switch  (shareable preset package)")
// This is the data contract behind the app's upload/download/preset features.
let hub = PersonaEngine()
let zetaPreset = hub.createPersona(name: "zeta用")
try hub.learn(reading: "すき", surface: "好きかもしれない")
try hub.learn(reading: "あい", surface: "アイ（推し）")

// UPLOAD: turn a persona into a versioned, shareable preset
let preset = try hub.exportPackage(zetaPreset.id, note: "AIチャット用の語彙セット")
print("uploaded preset: \(preset.count) bytes (versioned, with display name + note)")

// DOWNLOAD: a friend pulls the preset onto their device (always a fresh copy)
let friend = PersonaEngine()
let friendDaily = friend.createPersona(name: "日常用")   // they already had their own persona
try friend.seedDefaultLexicon()                          // ...seeded with defaults
let downloaded = try friend.importPackage(from: preset, activate: true)
print("downloaded as preset:", downloaded.name)
print("friend すき (zeta preset active) →", friend.complete(reading: "すき"))

// PRESET SWITCH: flip back to their own default-seeded persona
try friend.switchPersona(to: friendDaily.id)
print("after preset switch active:", friend.activePersona?.name ?? "-")
print("friend すき (日常用 active)      →", friend.complete(reading: "すき"))

show("done — all M0 + M1 features working on \(ProcessInfo.processInfo.operatingSystemVersionString)")
