// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var package = Package(
    name: "Substrate",
    products: [
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
    ],
    dependencies: [
        .package(url: "https://github.com/tesseract-one/swift-scale-codec.git", from: "0.2.0"),
        .package(url: "https://github.com/tesseract-one/Blake2.swift.git", from: "0.1.2"),
        .package(url: "https://github.com/tesseract-one/UncommonCrypto.swift.git", from: "0.1.0"),
        .package(url: "https://github.com/tesseract-one/Sr25519.swift.git", from: "0.1.3"),
        .package(url: "https://github.com/tesseract-one/CSecp256k1.swift.git", .branch("main")),
        .package(url: "https://github.com/tesseract-one/Bip39.swift.git", from: "0.1.1"),
        .package(url: "https://github.com/daisuke-t-jp/xxHash-Swift.git", from: "1.1.0"),
        .package(url: "https://github.com/tesseract-one/Serializable.swift.git", from: "0.2.0"),
        .package(url: "https://github.com/tesseract-one/WebSocket.swift.git", from: "0.0.7"),
    ],
    targets: [
        .target(
            name: "Polkadot",
            dependencies: ["Substrate"]),
        .target(
            name: "Substrate",
            dependencies: ["SubstratePrimitives", "SubstrateRpc"]),
        .target(
            name: "SubstratePrimitives",
            dependencies: [
                .product(name: "ScaleCodec", package: "swift-scale-codec"),
                "xxHash-Swift", "Blake2"
            ],
            path: "Sources/Primitives"),
        .target(
            name: "SubstrateRpc",
            dependencies: ["WebSocket"],
            path: "Sources/RPC"),
        .target(
            name: "SubstrateKeychain",
            dependencies: ["Substrate", "Sr25519", "Ed25519", "CSecp256k1", "Bip39", "UncommonCrypto"],
            path: "Sources/Keychain"),
        .testTarget(
            name: "KeychainTests",
            dependencies: ["SubstrateKeychain"]),
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
