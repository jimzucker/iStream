// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "iStream",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "iStream", targets: ["iStream"]),
    ],
    targets: [
        .target(
            name: "iStream",
            path: "Sources/iStream"
        ),
        .testTarget(
            name: "iStreamTests",
            dependencies: ["iStream"],
            path: "Tests/iStreamTests"
        ),
    ]
)
