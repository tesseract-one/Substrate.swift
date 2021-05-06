// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var package = Package(
    name: "Substrate",
    platforms: [.iOS(.v11), .macOS(.v10_12)],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Polkadot",
            targets: ["Polkadot"]),
        .library(
            name: "Substrate",
            targets: ["Substrate"]),
        .library(
            name: "SubstratePrimitives",
            targets: ["SubstratePrimitives"]),
        .library(
            name: "SubstrateRpc",
            targets: ["SubstrateRpc"]),
        .library(
            name: "SubstrateKeychain",
            targets: ["SubstrateKeychain"]),
        .library(
            name: "CBlake2b",
            targets: ["CBlake2b"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(name: "swift-scale-codec", url: "https://github.com/tesseract-one/swift-scale-codec.git", .branch("main")),
        .package(name: "Sr25519", url: "https://github.com/tesseract-one/sr25519.swift.git", .branch("main")),
        .package(name: "CryptoSwift", url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.4.0"),
        .package(name: "xxHash-Swift", url: "https://github.com/daisuke-t-jp/xxHash-Swift.git", from: "1.1.0"),
        .package(name: "Serializable", url: "https://github.com/tesseract-one/Serializable.swift.git", from: "0.2.0"),
        .package(name: "WebSocket", url: "https://github.com/tesseract-one/WebSocket.swift.git", from: "0.0.4"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Polkadot",
            dependencies: ["Substrate"]),
        .target(
            name: "Substrate",
            dependencies: ["SubstratePrimitives", "SubstrateRpc"]),
        .target(
            name: "CBlake2b",
            dependencies: []),
        .target(
            name: "SubstratePrimitives",
            dependencies: [
                .product(name: "ScaleCodec", package: "swift-scale-codec"),
                "xxHash-Swift", "CBlake2b"
            ],
            path: "Sources/Primitives"),
        .target(
            name: "SubstrateRpc",
            dependencies: ["WebSocket"],
            path: "Sources/RPC"),
        .target(
            name: "SubstrateKeychain",
            dependencies: ["Substrate", "Sr25519", "CryptoSwift"],
            path: "Sources/Keychain"),
        .testTarget(
            name: "PolkadotTests",
            dependencies: ["Polkadot"]),
        .testTarget(
            name: "SubstrateTests",
            dependencies: ["Substrate"]),
        .testTarget(
            name: "PrimitivesTests",
            dependencies: ["SubstratePrimitives"]),
        .testTarget(
            name: "RPCTests",
            dependencies: ["SubstrateRpc", "Serializable"]),
    ]
)
