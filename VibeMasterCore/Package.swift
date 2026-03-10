// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VibeMasterCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(name: "VibeMasterCore", targets: ["VibeMasterCore"]),
    ],
    targets: [
        .target(
            name: "VibeMasterCore",
            dependencies: [],
            path: "Sources/VibeMasterCore"
        ),
        .testTarget(
            name: "VibeMasterCoreTests",
            dependencies: ["VibeMasterCore"],
            path: "Tests/VibeMasterCoreTests"
        ),
    ]
)
