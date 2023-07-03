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

### Initialization

For initialization Substrate needs client and runtime config. For now there is only one client - JsonRPC.

```swift
import Substrate
// Not needed for CocoaPods
import SubstrateRPC

let nodeUrl = URL(string: "wss://westend-rpc.polkadot.io")!

let substrate = try await Substrate(
    rpc: JsonRpcClient(.ws(url: nodeUrl)),
    config: DynamicConfig()
)
```

### Submit Extrinsic
```swift
// Not needed for CocoaPods
import SubstrateKeychain

let mnemonic = "your key 12 words"
let from = try Sr25519KeyPair(parsing: mnemonic + "//Key1") // hard key derivation

let to = try substrate.runtime.address(ss58: "account s58 address")

let call = try AnyCall(name: "transfer",
                       pallet: "Balances",
                       map: ["dest": to, "value": 15483812850])
let tx = try await substrate.tx.new(call)
let events = try await tx.signSendAndWatch(signer: from)
        .waitForFinalized()
        .success()
print("Events: \(try events.parsed())")
```

### Runtime Calls
For runtime calls node should support Metadata v15.

```swift

guard substrate.call.has(method: "versions", api: "Metadata") else {
  fatalError("Node does't have needed call")
}

// Array<UInt32> is a return value for the call
// Value<RuntimeTypeId> can be used for fully dynamic parsing
// AnyValueRuntimeCall is a typealias for fully dynamic call
let call = AnyRuntimeCall<[UInt32]>(api: "Metadata",
                                    method: "versions")

let versions = try await substrate.call.execute(call: call)

print("Supported metadata versions: \(versions)")
```

### Constants
```swift

let deposit = try substrate.constants.get(UInt128.self, name: "ExistentialDeposit", pallet: "Balances")

print("Existential deposit: \(deposit)")
```

### Storage Keys
Storage API works through `StorageEntry` helpers, which can be created for some `StorageKey` type.

#### Create StorageEntry for key
```swift
// Typed value
let entry = try storage.query.entry(UInt128.self, name: "NominatorSlashInEra", pallet: "Stacking")

// Dynamic value. Entry type is Value<RuntimeTypeId>
let entry = storage.query.valueEntry(name: "NominatorSlashInEra", pallet: "Stacking")
```

#### Fetch key value
When we have entry we can fetch values.
```swift
let accountId = try substrate.runtime.account(ss58: "EoukLS2Rzh6dZvMQSkqFy4zGvqeo14ron28Ue3yopVc8e3Q")
// NominatorSlashInEra is Double Map (EraIndex, AccountId).
// We have to provide 2 keys to get value.

// Optional value
let optSlash = try await entry.value(path: Tuple(652, accountId))
print("Value is: \(optSlash ?? 0)")

// Default value used
let slash = try await entry.valueOrDefault(path: Tuple(652, accountId))
print("Value is: \(slash)")
```

#### Key Iterators
Map keys support iteration. StorageEntry has set of helpers for this functionality. 
```swift
// We can iterate over Key/Value pairs.
for try await (key, value) in entry.entries() {
  print("Key: \(key), value: \(value)")
}

// Or only keys
for try await key in entry.keys() {
  print("Key: \(key)")
}

// For maps where N > 1 we can filter iterator by first N-1 keys
// This will set EraIndex value to 652
let filtered = entry.filter(key: 652)
// And iterate over filtered Key/Value pairs.
for try await (key, value) in filtered.entries() {
  print("Key: \(key), value: \(value)")
}
```

#### Subscribe for changes
If substrate network client support subscription we can subscribe for storage changes.
```swift
// Some account we want to watch
let ALICE = try substrate.runtime.account(ss58: "5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY")

// Dynamic entry for System.Account storage key
let entry = try storage.query.valueEntry(name: "Account", pallet: "System")

// It's a Map parameter so we should pass key to watch
for try await account in entry.watch(path: [ALICE]) {
  print("Account updated: \(account)")
}
```

### Custom RPC calls
Current SDK wraps only basic system calls needed for its APIs. For more calls common call API can be used. 
```swift
// Simple call
let blockHash: Data = try await substrate.rpc.call(method: "chain_getBlockHash", params: Params(0))

// Subscription
let stream = try await substrate.rpc.subscribe(
  method: "chain_subscribeNewHeads",
  params: Params(),
  unsubscribe: "chain_unsubscribeNewHeads",
  DynamicConfig.TBlock.THeader.self
)
```

### Key Chain API
```swift
```

## Author

 - [Tesseract Systems, Inc.](mailto:info@tesseract.one)
   ([@tesseract_one](https://twitter.com/tesseract_one))

## License

Substrate.swift is available under the Apache 2.0 license. See [the LICENSE file](./LICENSE) for more information.

