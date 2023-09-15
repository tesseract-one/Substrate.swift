# Core SDK protocols

## SCALE Encoding/Decoding protocols
### `RuntimeLazyDynamicDecodable`, `RuntimeLazyDynamicEncodable`, `RuntimeLazyDynamicCodable`
Base protocols for all SCALE codable structures. Accept runtime and lazy type definition. Should never be implemented directly. Will be automatically implemented by one of the child protocols. Should be used only at core-level to support all types of structures (dynamic+static).

### Static coding
#### `RuntimeDecodable`, `RuntimeEncodable`, `RuntimeCodable`
For structures that can be decoded without type definitions (static). Only runtime is passed to them. Should be implemented by all static structures (`StaticCall`, `StaticEvent`, `StaticStorageKey`, etc.)

#### `ScaleCodec.Encodable`, `ScaleCodec.Decodale`, `ScaleCodec.Codable`
For fully static structures that even don't need runtime for coding. Lazy protocols should be added to this structures too, without any implementations (will be provided automatically).

### Dynamic coding
#### `RuntimeDynamicDecodable`, `RuntimeDynamicEncodable`, `RuntimeDynamicCodable`
Base protocol for dynamic types. This types can be encoded/decoded only by providing type definition. Implemented by `Value` and all dynamic types - `AnyCall`, `AnyEvent`, `AnyStorageKey`, `AnyRuntimeCall`, `AnySignature` etc.

#### `DynamicDecodable`, `DynamicEncodable`, `DynamicCodable`
Stronger protocol for types that can be coded without runtime only by providing type definition. Automatically implement Dynamic protocols. Implemented by `Value` and some core types.

## JSON Encoding/Decoding protocols.
### `RuntimeLazyDynamicSwiftEncodable`, `RuntimeLazyDynamicSwiftDecodable`, `RuntimeLazyDynamicSwiftCodable`
Base protocol for all JSON codable structures. Should never be implemented directly. Used only in the core. One of the children protocols should be implemented instead. Doesn't have own coding context implementation, only protocol.

### Static coding
#### `RuntimeSwiftDecodable`, `RuntimeSwiftEncodable`, `RuntimeSwiftCodable`
##### Coding Context: `RuntimeCodableContext`
For structures that can be encoded/decoded with runtime only. Implemented by all static structures.

#### `Encodable`, `Decodable`, `Codable`
##### Coding Context: `VoidCodableContext`
Built-in Swift protocols for JSON coding. Implemented by fully static structures that don't need runtime for coding.
Lazy protocols should be added to them without any implementation.

### Dynamic coding
#### `RuntimeDynamicSwiftDecodable`, `RuntimeDynamicSwiftEncodable`, `RuntimeDynamicSwiftCodable`
##### Coding Context: `RuntimeDynamicCodableContext`
Protocol for structures that need Runtime and Type Definition for coding. All dynamic types in the SDK.

#### `DynamicSwiftDecodable`, `DynamicSwiftEncodable`, `DynamicSwiftCodable`
##### Coding Context: `DynamicCodableContext`
Stronger protocol for types that can be coded without runtime only by providing type definition. Automatically implement Dynamic protocols. Implemented by `Value` and some core types.

## Validation protocols
### `ValidatableTypeDynamic`
Most top-level protocol for type validation. Provides dynamic runtime-based validation. Implemented directly by Compact, Data, Arrays. Allows dynamic type check (like integer overflow even if type sizes is different).

### `ValidatableTypeStatic`
Protocol that implemented as static method. Allows validation at the runtime initialization. Main protocol for implementation by custom types. Provides default implementation for `ValidatableTypeDynamic`.

### `ComplexValidatableType`
Helper protocol which splits type info parsing and validation steps.

### `CompositeValidatableType`, `CompositeStaticValidatableType`
Helper protocols to simplify validation of composite types. Automatically parses Type Definition and extracts fields. Static protocol can match them with provided field types.

### `VariantValidatableType`, `VariantStaticValidatableType`
Helper protocols to simplify validation of variant types. Automatically parses Type Definition and extracts variants with fields. Static protocol can match them with provided variant types.

## Value Representable protocol
Depends on `ValidatableTypeDynamic` protocol. Allows usage of type with dynamic `AnyCall`, `AnyRuntimeCall` and `AnyStorageKey` objects. Provides a way to convert some value to the proper `Value` object with attached Type Definition, which then can be encoded to SCALE/JSON. Do a runtime validation before conversion, and throws errors if value can't be converted. Implemented by all basic types in SDK.

## Identifiable types
### `IdentifiableTypeStatic` protocol
Main protocol for identifiable types. It allows to provide definition for the type. Automatically implements `ValidatableTypeStatic` protocol. Fully static types should be defined as `IdentifiableType`.

### `IdentifiableWithConfigTypeStatic` and `IdentifiableTypeCustomWrapperStatic` protocols
Helper protocols for identifiable types which allow to pass parameters to the static method. Usable for Data/Compact/Arrays to provide configuration like dynamic/fixed.

## Frame Types Protocols

Protocols for types attached to Pallets/Runtime API which could be obtained from metadata directly: `Call`, `Event`, `StorageKey`, `PalletError`, `Constant`, `RuntimeCall`,

### `RuntimeValidatableType`
Frame equivalent to the `ValidatableTypeDynamic`. Validates frame type with provided runtime. Implemented by dynamic frame types.

### `FrameType`
Basic protocol for all static frame types. Provides interface for type identification and validation.

### `ComplexFrameType` and `ComplexStaticFrameType`
Helper protocols for frame types for simpler validation implementation.

### `IdentifiableFrameType`
Frame type equivalent for `IdentifiableTypeStatic`. Provides own version of Type Definition. Provides default implementation for validation. Default target for implementation for static frame types.
