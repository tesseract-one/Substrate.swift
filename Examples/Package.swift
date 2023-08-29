// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Examples",
    platforms: [.macOS(.v11), .iOS(.v14), .tvOS(.v14), .watchOS(.v7), .macCatalyst(.v14)],
    products: [
        .executable(
            name: "BalanceTransaction",
            targets: ["BalanceTransaction"]),
    ],
    dependencies: [
        .package(path: "../")
    ],
    targets: [
        .executableTarget(
            name: "BalanceTransaction",
            dependencies: [
                .product(name: "Substrate", package: "Substrate.swift"),
                .product(name: "SubstrateRPC", package: "Substrate.swift"),
                .product(name: "SubstrateKeychain", package: "Substrate.swift")
            ]
        ),
    ]
)
