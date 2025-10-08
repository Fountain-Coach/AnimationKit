// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AnimationKit",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(name: "AnimationKit", targets: ["AnimationKit"]),
        .library(name: "AnimationKitClient", targets: ["AnimationKitClient"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.5.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "AnimationKit",
            dependencies: [],
            path: "Sources/AnimationKit"
        ),
        .target(
            name: "AnimationKitClient",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession")
            ],
            path: "Sources/AnimationKitClient",
            resources: [
                .copy("openapi.yaml")
            ],
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
            ]
        ),
        .testTarget(
            name: "AnimationKitTests",
            dependencies: ["AnimationKit"],
            path: "Tests/AnimationKitTests"
        ),
        .testTarget(
            name: "AnimationKitClientTests",
            dependencies: ["AnimationKitClient"],
            path: "Tests/AnimationKitClientTests"
        )
    ]
)
