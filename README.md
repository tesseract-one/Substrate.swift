# Substrate.swift

![🐧 linux: ready](https://img.shields.io/badge/%F0%9F%90%A7%20linux-ready-red.svg)
[![GitHub license](https://img.shields.io/badge/license-Apache%202.0-lightgrey.svg)](https://raw.githubusercontent.com/tesseract-one/Substrate.swift/main/LICENSE)
[![Build Status](https://github.com/tesseract-one/Substrate.swift/workflows/Build%20%26%20Tests/badge.svg?branch=main)](https://github.com/tesseract-one/Substrate.swift/actions?query=workflow%3ABuild%20%26%20Tests+branch%3Amain)
[![GitHub release](https://img.shields.io/github/release/tesseract-one/Substrate.swift.svg)](https://github.com/tesseract-one/Substrate.swift/releases)
[![SPM compatible](https://img.shields.io/badge/SwiftPM-Compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![CocoaPods version](https://img.shields.io/cocoapods/v/Substrate.swift.svg)](https://cocoapods.org/pods/Substrate.swift)
![Platform OS X | iOS | tvOS | watchOS | Linux](https://img.shields.io/badge/platform-Linux%20%7C%20OS%20X%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS-orange.svg)

### Swift SDK for Substrate based networks

## Getting started

### Installation

#### [Package Manager](https://swift.org/package-manager/)

Add the following dependency to your [Package.swift](https://github.com/apple/swift-package-manager/blob/master/Documentation/Usage.md#define-dependencies):

```swift
.package(url: "https://github.com/tesseract-one/Substrate.swift.git", from: "0.0.1")
```

And add library dependencies to your target
```swift
// Main and RPC
.product(name: "Substrate", package: "Substrate.swift"),
.product(name: "SubstrateRPC", package: "Substrate.swift"),
// Keychain
.product(name: "SubstrateKeychain", package: "Substrate.swift"),
```

Run `swift build` and build your app.

#### [CocoaPods](http://cocoapods.org/)

Add the following to your [Podfile](http://guides.cocoapods.org/using/the-podfile.html):

```rb
# Main and RPC
pod 'Substrate/Substrate', '~> 0.0.1'
pod 'Substrate/RPC', '~> 0.0.1'
# Keychain
pod 'Substrate/Keychain', '~> 0.0.1'
```

Then run `pod install`

## Author

 - [Tesseract Systems, Inc.](mailto:info@tesseract.one)
   ([@tesseract_one](https://twitter.com/tesseract_one))

## License

Substrate.swift is available under the Apache 2.0 license. See [the LICENSE file](./LICENSE) for more information.

