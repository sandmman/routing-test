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
        .package(url: "https://github.com/IBM-Swift/Kitura-CORS", .upToNextMinor(from: "2.0.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(name: "Contracts", dependencies: []),
        .target(name: "Models", dependencies: [.target(name: "Contracts")]),
        .target(name: "Client", dependencies: [.target(name: "Models")]),
        .target(name: "RouterExtension", dependencies: [.target(name: "Models"), "Kitura"]),
        .target(
            name: "Server",
            dependencies: [.target(name: "Models"), .target(name: "RouterExtension"), "Kitura"]
        ),
    ]
)
