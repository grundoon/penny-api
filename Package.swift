// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "penny",
    products: [
        .library(name: "PennyConnector", targets: ["PennyConnector"]),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0-rc"),
        .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0-rc"),
    ],
    targets: [
        // The API
        .target(name: "Mint", dependencies: ["FluentPostgreSQL", "Vapor"]),
        .target(name: "Penny", dependencies: ["FluentPostgreSQL", "Vapor", "Mint"]),
        .target(name: "Run", dependencies: ["Penny"]),

        // The API Connector
        .target(name: "PennyConnector", dependencies: ["Vapor", "Mint", "Penny"]),

        // Tests
        .testTarget(name: "PennyTests", dependencies: ["Penny"]),
        .testTarget(name: "MintTests", dependencies: ["Mint"])
    ]
)

