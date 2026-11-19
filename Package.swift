// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SoundBar",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "FocusKit"),
        .executableTarget(name: "focusbar", dependencies: ["FocusKit"]),
        .testTarget(name: "FocusKitTests", dependencies: ["FocusKit"]),
    ]
)
