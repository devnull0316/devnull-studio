// swift-tools-version: 5.9
// PersonaEngine — cross-platform predictive-text engine with switchable persona layers.
//
// This package is deliberately Foundation-only (no UIKit / no iOS SDK) so that it
// builds and is fully unit-tested on Windows and Linux *today*, and is later
// imported unchanged by the iOS keyboard extension (built on a cloud Mac).
import PackageDescription

let package = Package(
    name: "PersonaEngine",
    products: [
        .library(name: "PersonaEngine", targets: ["PersonaEngine"]),
        .executable(name: "persona-demo", targets: ["persona-demo"]),
    ],
    targets: [
        .target(name: "PersonaEngine"),
        .executableTarget(name: "persona-demo", dependencies: ["PersonaEngine"]),
        .testTarget(name: "PersonaEngineTests", dependencies: ["PersonaEngine"]),
    ]
)
