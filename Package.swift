// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ScrcpyConnect",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ScrcpyConnect",
            path: "Sources",
            exclude: ["Info.plist"]
        )
    ]
)
