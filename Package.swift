// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Kitura-Next",
    products: [
        .executable(
            name: "server",
            targets: ["Server"]
        ),
        .executable(
            name: "client",
            targets: ["Client"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/IBM-Swift/Kitura.git", .branch("issue.encoding")),
        .package(url: "https://github.com/IBM-Swift/KituraKit.git", .branch("ro-auth")),
        .package(url: "https://github.com/IBM-Swift/Kitura-CredentialsHTTP.git", .branch("ro-codable")),
        .package(url: "https://github.com/IBM-Swift/HeliumLogger.git", .upToNextMajor(from: "1.7.1")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(name: "Extensions", dependencies: []),
        .target(name: "KituraKitExtensions", dependencies: ["KituraKit", "Contracts", "Models", "Extensions"]),
        .target(name: "Contracts", dependencies: ["Kitura", "Extensions"]),
        .target(name: "Models", dependencies: ["Contracts", "CredentialsHTTP"]),
        .target(name: "Client", dependencies: ["Models", "KituraKitExtensions"]),
        .target(name: "RouterExtension", dependencies: ["Models", "Extensions", "Contracts", "Kitura"]),
        .target(
            name: "Server",
            dependencies: ["Models", "RouterExtension", "Kitura", "HeliumLogger"]
        ),
    ]
)
