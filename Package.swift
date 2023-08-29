// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "Substrate",
    platforms: [.macOS(.v11), .iOS(.v14), .tvOS(.v14), .watchOS(.v7), .macCatalyst(.v14)],
    products: [
        .library(
            name: "Substrate",
            targets: ["Substrate"]),
        .library(
            name: "SubstrateKeychain",
            targets: ["SubstrateKeychain"]),
        .library(
            name: "SubstrateRPC",
            targets: ["SubstrateRPC"]),
    ],
    dependencies: [
        .package(url: "https://github.com/oscbyspro/Numberick.git", .upToNextMinor(from: "0.10.0")),
        .package(url: "https://github.com/tesseract-one/xxHash.swift.git", .upToNextMinor(from: "0.1.0")),
        .package(url: "https://github.com/tesseract-one/ScaleCodec.swift.git", .upToNextMinor(from: "0.3.1")),
        .package(url: "https://github.com/tesseract-one/ContextCodable.swift.git", .upToNextMinor(from: "0.1.0")),
        .package(url: "https://github.com/tesseract-one/Tuples.swift.git", .upToNextMinor(from: "0.1.0")),
        .package(url: "https://github.com/tesseract-one/Blake2.swift.git", .upToNextMinor(from: "0.1.2")),
        .package(url: "https://github.com/tesseract-one/UncommonCrypto.swift.git", .upToNextMinor(from: "0.1.3")),
        .package(url: "https://github.com/tesseract-one/Sr25519.swift.git", .upToNextMinor(from: "0.1.3")),
        .package(url: "https://github.com/tesseract-one/CSecp256k1.swift.git", .upToNextMinor(from: "0.1.0")),
        .package(url: "https://github.com/tesseract-one/Bip39.swift.git", .upToNextMinor(from: "0.1.1")),
        .package(url: "https://github.com/tesseract-one/Serializable.swift.git", .upToNextMinor(from: "0.2.3")),
        .package(url: "https://github.com/tesseract-one/JsonRPC.swift.git", .upToNextMinor(from: "0.2.2")),
    ],
    targets: [
        .target(
            name: "Substrate",
            dependencies: [
                .product(name: "Serializable", package: "Serializable.swift"),
                .product(name: "ScaleCodec", package: "ScaleCodec.swift"),
                .product(name: "ContextCodable", package: "ContextCodable.swift"),
                .product(name: "Blake2", package: "Blake2.swift"),
                .product(name: "Tuples", package: "Tuples.swift"),
                .product(name: "xxHash", package: "xxHash.swift"),
                "Numberick"
            ]),
        .target(
            name: "SubstrateKeychain",
            dependencies: [
                .product(name: "Sr25519", package: "Sr25519.swift"),
                .product(name: "Ed25519", package: "Sr25519.swift"),
                .product(name: "CSecp256k1", package: "CSecp256k1.swift"),
                .product(name: "Bip39", package: "Bip39.swift"),
                .product(name: "UncommonCrypto", package: "UncommonCrypto.swift"),
                "Substrate"
            ],
            path: "Sources/Keychain"),
        .target(
            name: "SubstrateRPC",
            dependencies: [
                .product(name: "Serializable", package: "Serializable.swift"),
                .product(name: "JsonRPC", package: "JsonRPC.swift"),
                "Substrate"
            ],
            path: "Sources/RPC"),
        .testTarget(
            name: "KeychainTests",
            dependencies: ["SubstrateKeychain"]),
        .testTarget(
            name: "SubstrateTests",
            dependencies: ["Substrate"],
            resources: [.copy("Resources")]),
        .testTarget(
            name: "IntegrationTests",
            dependencies: ["Substrate", "SubstrateKeychain", "SubstrateRPC"])
    ]
)
