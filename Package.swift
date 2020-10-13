// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Substrate",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Polkadot",
            targets: ["Polkadot"]),
        .library(
            name: "SubstratePrimitives",
            targets: ["Primitives"]),
        .library(
            name: "CBlake2b",
            targets: ["CBlake2b"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/tesseract-one/swift-scale-codec.git", from: "0.1.0"),
        .package(url: "https://github.com/daisuke-t-jp/xxHash-Swift.git", from: "1.1.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Polkadot",
            dependencies: ["Primitives"]),
        .target(
            name: "CBlake2b",
            dependencies: []),
        .target(
            name: "Primitives",
            dependencies: ["ScaleCodec", "xxHash-Swift", "CBlake2b"]),
        .testTarget(
            name: "PolkadotTests",
            dependencies: ["Polkadot"]),
        .testTarget(
            name: "PrimitivesTests",
            dependencies: ["Primitives"]),
    ]
)
