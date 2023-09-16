# Frame Types

Frame types is a class of types which is bound to frame/runtime API. Inside SDK they have own Type Definition realization and RuntimeCodable by default.

## Call
Provided by `AnyCall` structure for dynamic calls, and `PalletCall` and `StaticCall` protocols for static calls.

`StaticCall` is a fully static protocol and provides partial implementation for encoding and decoding.

## Event
Provided the same way by `AnyEvent` dynamic structure, and `PalletEvent` and `StaticEvent` protocols.

`StaticEvent` is a best and simplet option for implementation.

## Runtime Call
Provided by `AnyRuntimeCall` dynamic implementation and `StaticRuntimeCall` protocol for static implementations.

## Constants
`StaticConstant` and `ValidatableStaticConstant` protocols. Secon supports validation of the contant value type.

## Errors
`PalletError` and `StaticPalletError` protocols. Second one provides `typeInfo` for type validation.

## Storage Keys
`AnyStorageKey` for dynamic storage keys.

### Base protocols
`PalletStorageKey` and `StaticStorageKey` for static storage key implementations.

`IterableStorageKey` and `StorageKeyIterator` for iterable storage key implementation.

`IterableStorageKeyIterator` for double and n-map keys static keys.

### Default implementations
SDK provides helpers for common key types for simpler implementation:
1. `PlainStorageKey` - for plain storage keys
2. `MapStorageKey` - map storage keys
3. `DoubleMapStorageKey` - for double-map keys.

### N-map keys
N-map keys can be implemented through tuple keys via `TupleStorageKey` protocol and `Tuple1...Tuple15` structures.

## Frame type

This is a top-level type which can be used for all frame types registration. It's a protocol defined as:
```swift
public protocol Frame: RuntimeValidatableType {
    static var name: String { get }
    
    var calls: [PalletCall.Type] { get }
    var events: [PalletEvent.Type] { get }
    var errors: [StaticPalletError.Type] { get }
    var storageKeys: [any PalletStorageKey.Type] { get }
    var constants: [any StaticConstant.Type] { get }
}
```
Example implementation can be found in the [CustomStaticConfig](../Examples/Sources/CustomStaticConfig/) application.

There are `Frame`-prefixed protocols for all static frame types, which accepts Frame as associated type. They all defined in the [Frame.swift](../Sources/Substrate/Types/Frame.swift) file.