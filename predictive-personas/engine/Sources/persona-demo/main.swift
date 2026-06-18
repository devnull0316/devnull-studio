import Foundation
import PersonaEngine

// A scripted demo you can run on Windows TODAY with:  swift run persona-demo
// It shows the whole product thesis without a phone or a Mac:
// named persona layers, isolated learning, switching, and carry (export/import).

func show(_ title: String) { print("\n=== \(title) ===") }

let engine = PersonaEngine()

show("1) Create two persona layers")
let daily = engine.createPersona(name: "日常用")
let zeta  = engine.createPersona(name: "zeta用")        // becomes active
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

show("done")
