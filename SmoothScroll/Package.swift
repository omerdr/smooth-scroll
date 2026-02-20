// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SmoothScroll",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "SmoothScroll",
            path: "SmoothScroll",
            resources: [
                .process("Info.plist")
            ]
        )
    ]
)
