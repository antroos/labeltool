// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "WeLabelDataRecorder",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(
            name: "WeLabelDataRecorder",
            targets: ["WeLabelDataRecorder"]
        )
    ],
    dependencies: [
        // No external dependencies for the initial setup
    ],
    targets: [
        .executableTarget(
            name: "WeLabelDataRecorder",
            dependencies: [],
            path: "WeLabelDataRecorder/Sources"
        ),
        .testTarget(
            name: "WeLabelDataRecorderTests",
            dependencies: ["WeLabelDataRecorder"],
            path: "WeLabelDataRecorder/Tests"
        )
    ]
) 