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

For initialization `Api` needs client and runtime config. For now there is only one client - JsonRPC.

```swift
import Substrate
// Import not needed for CocoaPods.
// In CocoaPods all types are inside one Substrate module.
import SubstrateRPC

let nodeUrl = URL(string: "wss://westend-rpc.polkadot.io")!

// Dynamic Config should work for almost all Substrate based networks.
// It's not most eficient though because uses a lot of dynamic types
let substrate = try await Api(
    rpc: JsonRpcClient(.ws(url: nodeUrl)),
    config: .dynamic
)
```

### Submit Extrinsic
```swift
// Not needed for CocoaPods
import SubstrateKeychain

// Create KeyPair for signing
let mnemonic = "your key 12 words"
let from = try Sr25519KeyPair(parsing: mnemonic + "//Key1") // hard key derivation

// Create recipient address from ss58 string
let to = try substrate.runtime.address(ss58: "recipient s58 address")

// Dynamic Call type with Map parameters.
// any ValueRepresentable type can be used as parameter
let call = try AnyCall(name: "transfer",
                       pallet: "Balances",
                       map: ["dest": to, "value": 15483812850])

// Create Submittable (transaction) from the call
let tx = try await substrate.tx.new(call)

// We are using direct signer API here
// Or we can set Keychain as signer in Api and provide `account` parameter
// `waitForFinalized()` will wait for block finalization
// `waitForInBlock()` will wait for inBlock status
// `success()` will search for failed event and throw in case of failure
let events = try await tx.signSendAndWatch(signer: from)
        .waitForFinalized()
        .success()

// `parsed()` will dynamically parse all extrinsic events.
// Check `ExtrinsicEvents` struct for more efficient search methods.
print("Events: \(try events.parsed())")
```

### Runtime Calls
For dynamic runtime calls node should support Metadata v15.

```swift
// We can check does node have needed runtime call
guard substrate.call.has(method: "versions", api: "Metadata") else {
  fatalError("Node doesn't have needed call")
}

// Array<UInt32> is a return value for the call
// AnyValueRuntimeCall can be used for dynamic return parsing
let call = AnyRuntimeCall<[UInt32]>(api: "Metadata",
                                    method: "versions")

// Will parse vall result to Array<UInt32>
let versions = try await substrate.call.execute(call: call)

print("Supported metadata versions: \(versions)")
```

### Constants
```swift
// It will throw if constant is not found or type is wrong
let deposit = try substrate.constants.get(UInt128.self, name: "ExistentialDeposit", pallet: "Balances")

// This will parse constant to dynamic Value<RuntimeTypeId>
let dynDeposit = try substrate.constants.dynamic(name: "ExistentialDeposit", pallet: "Balances")

print("Existential deposit: \(deposit), \(dynDeposit)")
```

### Storage Keys
Storage API works through `StorageEntry` helper, which can be created for provided `StorageKey` type.

#### Create StorageEntry for storage
```swift
// dynamic storage key wirh typed Value
let entry = try substrate.query.entry(UInt128.self, name: "NominatorSlashInEra", pallet: "Stacking")

// dynamic storage key with dynamic Value
let dynEntry = substrate.query.dynamic(name: "NominatorSlashInEra", pallet: "Stacking")
```

#### Fetch key value
When we have entry we can fetch key values.
```swift
// We want values for this account.
let accountId = try substrate.runtime.account(ss58: "EoukLS2Rzh6dZvMQSkqFy4zGvqeo14ron28Ue3yopVc8e3Q")

// NominatorSlashInEra storage is Double Map (EraIndex, AccountId).
// We have to provide 2 keys to get value.

// optional value
let optSlash = try await entry.value(keys: [652, accountId])
print("Value is: \(optSlash ?? 0)")

// default value used when nil
let slash = try await entry.valueOrDefault(keys: [652, accountId])
print("Value is: \(slash)")
```

#### Key Iterators
Map keys support iteration. `StorageEntry` has helpers for this functionality. 
```swift
// We can iterate over Key/Value pairs.
for try await (key, value) in entry.entries() {
  print("Key: \(key), value: \(value)")
}

// or only over keys
for try await key in entry.keys() {
  print("Key: \(key)")
}

// For maps where N > 1 we can filter iterator by first N-1 keys
// This will set EraIndex value to 652
let filtered = entry.filter(key: 652)

// now we can iterate over filtered Key/Value pairs.
for try await (key, value) in filtered.entries() {
  print("Key: \(key), value: \(value)")
}

// or only over keys
for try await key in filtered.keys() {
  print("Key: \(key)")
}
```

#### Subscribe for changes
If Api Client support subscription we can subscribe for storage changes.
```swift
// Some account we want to watch
let ALICE = try substrate.runtime.account(ss58: "5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY")

// Dynamic entry for System.Account storage key
let entry = try substrate.query.dynamic(name: "Account", pallet: "System")

// It's a Map parameter so we should pass key to watch
for try await account in entry.watch(path: [ALICE]) {
  print("Account updated: \(account)")
}
```

### Custom RPC calls
Current SDK wraps only RPC calls needed for its API. For more calls common call API can be used.
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

### Substrate Signer
Substrate SDK provides Signer protocol, which can be implenented for Extrinsic signing.

Signer can be used in two different ways:
1. It can be provided directly to the Extrinsic signing calls
2. It can be stored into `signer` property of the `Api` object. In this case account `PublicKey` should be provided for signing calls.

First way is good for KeyPair signing. Second is better for full Keychain.

Signer protocol:
```swift
protocol Signer {
    // get account with proper type
    func account(type: KeyTypeId, algos: [CryptoTypeId]) async -> Result<any PublicKey, SignerError>
    
    // Sign extrinsic payload
    func sign<RC: Config, C: Call>(
        payload: SigningPayload<C, RC.TExtrinsicManager>,
        with account: any PublicKey,
        runtime: ExtendedRuntime<RC>
    ) async -> Result<RC.TSignature, SignerError>
}
```

### Keychain API
SDK provides simple in-memory keychain with Secp256k1, Ed25519 and Sr25519 keys support.

#### Key Pairs
```swift
// Not needed for CocoaPods
import SubstrateKeychain

// Initializers
// New with random key (OS secure random is used)
let random = EcdsaKeyPair() // or Ed25519KeyPair / Sr25519KeyPair
// From Bip39 mnemonic
let mnemonic = Sr25519KeyPair(phrase: "your words")
// JS compatible path based parsing
let path = try Ed25519KeyPair(parsing: "//Alice")

// Key derivation (JS compatible)
let derived = try mnemonic.derive(path: [PathComponent(string: "//Alice")])

// Sign and verify
let data = Data(repeating: 1, count: 20)
let signature = derived.sign(message: data)
let isSigned = derived.verify(message: data, signature: signature)
```

#### Keychain
In-memory storage for multiple KeyPairs (multi-account support).

##### Initialization and base API
```swift
// Not needed for CocoaPods
import SubstrateKeychain

// Create empty keychain object with default delegate
let keychain = Keychain()

// Will be returned for account request
keychain.add(derived, for: .account)
// Key for ImOnline
keychain.add(random, for: .imOnline)
// Key for all types of requests
keychain.add(path)

// Search for PubKey registered for 'account' requests
let pubKey = keychain.publicKeys(for: .account).first!
// get KeyPair for this PubKey
let keyPair = keychain.keyPair(for: pubKey)!
```

##### Api Signer integration
Keychain can be set as `Signer` for `Api` instance for simpler account management and signing.

```swift
// Set substrate signer to created keychain instance
substrate.signer = keychain

// Fetch account from Keychain (it will call Keychain delegate for selection)
// Can be stored and reused as needed (active account)
let from = try await substrate.tx.account()

// Signer will return PublicKey from Keychain
// which should be converted to account or address for extrinsics
print("Account: \(try from.account(in: substrate))")

// We can provide this PublicKey as `account` to calls for signing.
// Signing call will be sent to Keychain through Signer protocol
let events = try await tx.signSendAndWatch(account: from)
        .waitForFinalized()
        .success()

// print parsed events
print("Events: \(try events.parsed())")
```

##### Keychain Delegate
Keychain has delegate object which can select public keys for the Signer protocol. It can be used to show UI with account selecter to the user or implement custom logic.

There is default `KeychainDelegateFirstFound` implementation which returns first found compatible key from the Keychain.

Protocol looks like this:
```swift
enum KeychainDelegateResponse {
    case cancelled
    case noAccount
    case account(any PublicKey)
}

protocol KeychainDelegate: AnyObject {
    func account(in keychain: Keychain,
                 for type: KeyTypeId,
                 algorithms algos: [CryptoTypeId]) async -> KeychainDelegateResponse
}
```

### Batch Extrinsics
SDK supports batch calls: [#how-can-i-batch-transactions](https://polkadot.js.org/docs/api/cookbook/tx#how-can-i-batch-transactions)
```swift
// Fetch account from Keychain (should be set in substrate as signer)
let from = try await substrate.tx.account()

// Create recipient addresses from ss58 string
let to1 = try substrate.runtime.address(ss58: "recipient1 s58 address")
let to2 = try substrate.runtime.address(ss58: "recipient2 s58 address")

// Create 2 calls
let call1 = try AnyCall(name: "transfer",
                        pallet: "Balances",
                        map: ["dest": to1, "value": 15483812850])
let call2 = try AnyCall(name: "transfer",
                        pallet: "Balances",
                        map: ["dest": to2, "value": 21234567890])

// Create batch transaction from the calls (batch or batchAll methods)
let tx = try await substrate.tx.batchAll([call1, call2])

// Sign, send and watch for finalization
let events = try await tx.signSendAndWatch(account: from)
        .waitForFinalized()
        .success()

// Parsed events
print("Events: \(try events.parsed())")
```

## Author

 - [Tesseract Systems, Inc.](mailto:info@tesseract.one)
   ([@tesseract_one](https://twitter.com/tesseract_one))

## License

Substrate.swift is available under the Apache 2.0 license. See [the LICENSE file](./LICENSE) for more information.

