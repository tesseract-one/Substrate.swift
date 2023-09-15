//
//  RuntimeCodable.swift
//  
//
//  Created by Yehor Popovych on 05.01.2023.
//

import Foundation
import ScaleCodec

// Type that doesn't need Type Definition for decoding.
// Most of the FrameTypes and dynamic types with definition in metadata.
public protocol RuntimeDecodable: RuntimeLazyDynamicDecodable {
    init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws
}

// Type that doesn't need Type Definition for encoding.
// Most of the FrameTypes and dynamic types with definition in metadata.
public protocol RuntimeEncodable: RuntimeLazyDynamicEncodable {
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws
}

// Codable typealias
public typealias RuntimeCodable = RuntimeEncodable & RuntimeDecodable

// ScaleCodec.Decodable is always RuntimeDecodable
public extension ScaleCodec.Decodable {
    @inlinable
    init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws {
        try self.init(from: &decoder)
    }
}

// ScaleCodec.Encodable is always RuntimeEncodable
public extension ScaleCodec.Encodable {
    @inlinable
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
        try encode(in: &encoder)
    }
}

// Type that needs Type Definition for decoding.
// Most of the runtime dynamic types.
public protocol RuntimeDynamicDecodable: RuntimeLazyDynamicDecodable {
    init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                `as` type: TypeDefinition,
                                runtime: any Runtime) throws
}

// Type that needs Type Definition for encoding.
// Most of the runtime dynamic types.
public protocol RuntimeDynamicEncodable: RuntimeLazyDynamicEncodable {
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E,
                                       `as` type: TypeDefinition,
                                       runtime: Runtime) throws
}

// Codable typealias
public typealias RuntimeDynamicCodable = RuntimeDynamicDecodable & RuntimeDynamicEncodable

// Base decodable protocol for all SCALE codable structures.
// Accepts runtime and lazy type definition.
// Should never be implemented directly. Will be automatically implemented by one of the child protocols.
// Should be used only at core-level as type restriction to support all types of structures (dynamic+static).
public protocol RuntimeLazyDynamicDecodable {
    init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                runtime: any Runtime,
                                lazy type: TypeDefinition.Lazy) throws
}

// Base encodable protocol for all SCALE codable structures.
// Accepts runtime and lazy type definition.
// Should never be implemented directly. Will be automatically implemented by one of the child protocols.
// Should be used only at core-level as type restriction to support all types of structures (dynamic+static).
public protocol RuntimeLazyDynamicEncodable {
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E,
                                       runtime: Runtime,
                                       lazy type: TypeDefinition.Lazy) throws
}

// Useful typealias for Codable types.
public typealias RuntimeLazyDynamicCodable = RuntimeLazyDynamicDecodable & RuntimeLazyDynamicEncodable

// Will detect proper implementation at runtime.
public extension RuntimeLazyDynamicDecodable {
    init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                runtime: any Runtime,
                                lazy type: TypeDefinition.Lazy) throws
    {
        switch Self.self {
        case let sself as ScaleCodec.Decodable.Type:
            self = try sself.init(from: &decoder) as! Self
        case let sself as RuntimeDecodable.Type:
            self = try sself.init(from: &decoder, runtime: runtime) as! Self
        case let sself as RuntimeDynamicDecodable.Type:
            self = try sself.init(from: &decoder, as: type(), runtime: runtime) as! Self
        default: fatalError("Never implement it directly! Use child protocols!")
        }
    }
}

// Will detect proper implementation at runtime.
public extension RuntimeLazyDynamicEncodable {
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E,
                                       runtime: Runtime,
                                       lazy type: TypeDefinition.Lazy) throws
    {
        switch self {
        case let sself as ScaleCodec.Encodable:
            try sself.encode(in: &encoder)
        case let sself as RuntimeEncodable:
            try sself.encode(in: &encoder, runtime: runtime)
        case let sself as RuntimeDynamicEncodable:
            try sself.encode(in: &encoder, as: type(), runtime: runtime)
        default: fatalError("Never implement it directly! Use child protocols!")
        }
    }
}


// Helper methods to encode and decode types.
public extension Runtime {
    @inlinable
    func decode<T: RuntimeDecodable, D: ScaleCodec.Decoder>(from decoder: inout D, _ type: T.Type) throws -> T {
        try T(from: &decoder, runtime: self)
    }
    
    @inlinable
    func decode<T: RuntimeDecodable, D: ScaleCodec.Decoder>(from decoder: inout D) throws -> T {
        try decode(from: &decoder, T.self)
    }
    
    @inlinable
    func decode<T: RuntimeDynamicDecodable, D: ScaleCodec.Decoder>(
        from decoder: inout D, type: T.Type, def: TypeDefinition
    ) throws -> T {
        try T(from: &decoder, as: def, runtime: self)
    }
    
    @inlinable
    func decode<T: RuntimeDynamicDecodable, D: ScaleCodec.Decoder>(
        from decoder: inout D, type: TypeDefinition
    ) throws -> T {
        try decode(from: &decoder, type: T.self, def: type)
    }
    
    @inlinable
    func decodeValue<D: ScaleCodec.Decoder>(
        from decoder: inout D, type: TypeDefinition
    ) throws -> Value<TypeDefinition> {
        try Value(from: &decoder, as: type, runtime: self)
    }
    
    @inlinable
    func decode<T: RuntimeLazyDynamicDecodable, D: ScaleCodec.Decoder>(
        from decoder: inout D, lazy type: T.Type, def: TypeDefinition
    ) throws -> T {
        try type.init(from: &decoder, runtime: self, lazy: { def })
    }
    
    @inlinable
    func decode<T: RuntimeLazyDynamicDecodable, D: ScaleCodec.Decoder>(
        from decoder: inout D, lazy type: TypeDefinition
    ) throws -> T {
        try decode(from: &decoder, lazy: T.self, def: type)
    }
    
    @inlinable
    func decode<T: RuntimeLazyDynamicDecodable, D: ScaleCodec.Decoder>(
        from decoder: inout D, type: T.Type,
        where def: TypeDefinition.Lazy
    ) throws -> T {
        try type.init(from: &decoder, runtime: self, lazy: def)
    }
    
    @inlinable
    func decode<T: RuntimeLazyDynamicDecodable, D: ScaleCodec.Decoder>(
        from decoder: inout D, where type: TypeDefinition.Lazy
    ) throws -> T {
        try decode(from: &decoder, type: T.self, where: type)
    }
    
    @inlinable
    func decode<T: RuntimeDecodable>(from data: Data, _ type: T.Type) throws -> T {
        var decoder = decoder(with: data)
        return try decode(from: &decoder, type)
    }
    
    @inlinable
    func decode<T: RuntimeDecodable>(from data: Data) throws -> T {
        try decode(from: data, T.self)
    }
    
    @inlinable
    func decode<T: RuntimeDynamicDecodable>(
        from data: Data, type: T.Type, def: TypeDefinition
    ) throws -> T {
        var decoder = decoder(with: data)
        return try decode(from: &decoder, type: type, def: def)
    }
    
    @inlinable
    func decode<T: RuntimeDynamicDecodable>(
        from data: Data, type: TypeDefinition
    ) throws -> T {
        try decode(from: data, type: T.self, def: type)
    }
    
    @inlinable
    func decodeValue(from data: Data, type: TypeDefinition) throws -> Value<TypeDefinition> {
        var decoder = decoder(with: data)
        return try decodeValue(from: &decoder, type: type)
    }
    
    @inlinable
    func decode<T: RuntimeLazyDynamicDecodable>(
        from data: Data, type: T.Type, def: TypeDefinition
    ) throws -> T {
        var decoder = decoder(with: data)
        return try decode(from: &decoder, lazy: type, def: def)
    }
    
    @inlinable
    func decode<T: RuntimeLazyDynamicDecodable>(
        from data: Data, lazy type: TypeDefinition
    ) throws -> T {
        try decode(from: data, type: T.self, def: type)
    }
    
    @inlinable
    func decode<T: RuntimeLazyDynamicDecodable>(
        from data: Data, type: T.Type,
        where def: TypeDefinition.Lazy
    ) throws -> T {
        var decoder = decoder(with: data)
        return try decode(from: &decoder, type: type, where: def)
    }
    
    @inlinable
    func decode<T: RuntimeLazyDynamicDecodable>(
        from data: Data, where def: TypeDefinition.Lazy
    ) throws -> T {
        try decode(from: data, type: T.self, where: def)
    }
    
    @inlinable
    func encode<T: RuntimeEncodable, E: ScaleCodec.Encoder>(value: T, in encoder: inout E) throws {
        try value.encode(in: &encoder, runtime: self)
    }
    
    @inlinable
    func encode<T: RuntimeDynamicEncodable, E: ScaleCodec.Encoder>(
        value: T, in encoder: inout E, `as` type: TypeDefinition
    ) throws {
        try value.encode(in: &encoder, as: type, runtime: self)
    }
    
    @inlinable
    func encode<T: RuntimeLazyDynamicEncodable, E: ScaleCodec.Encoder>(
        value: T, in encoder: inout E, lazy type: TypeDefinition
    ) throws {
        try value.encode(in: &encoder, runtime: self, lazy: { type })
    }
    
    @inlinable
    func encode<T: RuntimeLazyDynamicEncodable, E: ScaleCodec.Encoder>(
        value: T, in encoder: inout E, where type: TypeDefinition.Lazy
    ) throws {
        try value.encode(in: &encoder, runtime: self, lazy: type)
    }
    
    @inlinable
    func encode<T: RuntimeEncodable>(value: T) throws -> Data {
        var encoder = encoder()
        try encode(value: value, in: &encoder)
        return encoder.output
    }
    
    @inlinable
    func encode<T: RuntimeDynamicEncodable>(
        value: T, `as` type: TypeDefinition
    ) throws -> Data {
        var encoder = encoder()
        try encode(value: value, in: &encoder, as: type)
        return encoder.output
    }
    
    @inlinable
    func encode<T: RuntimeLazyDynamicEncodable>(
        value: T, lazy type: TypeDefinition
    ) throws -> Data {
        var encoder = encoder()
        try encode(value: value, in: &encoder, lazy: type)
        return encoder.output
    }
    
    @inlinable
    func encode<T: RuntimeLazyDynamicEncodable>(
        value: T, where type: TypeDefinition.Lazy
    ) throws -> Data {
        var encoder = encoder()
        try encode(value: value, in: &encoder, where: type)
        return encoder.output
    }
}

// Hook type which allows to customize encoding and decoding of dynamic types
// Runtime version of the CustomDynamicCoder.
// Used for UcheckedExtrinsic, because metadata is wrong for it and it should be
// encoded in a custom way
public protocol RuntimeCustomDynamicCoder {
    func check(type: TypeDefinition, in runtime: any Runtime) -> Bool
    
    func decode<D: ScaleCodec.Decoder>(
        from decoder: inout D, as type: TypeDefinition,
        in runtime: any Runtime
    ) throws -> Value<TypeDefinition>
    
    func encode<C, E: ScaleCodec.Encoder>(
        value: Value<C>, in encoder: inout E,
        as type: TypeDefinition, in runtime: any Runtime
    ) throws
    
    func decode(from container: inout ValueDecodingContainer,
                as type: TypeDefinition,
                in runtime: any Runtime) throws -> Value<TypeDefinition>
    
    func validate<C>(value: Value<C>, as type: TypeDefinition,
                     in runtime: any Runtime) -> Result<Void, TypeError>
    
    func dynamicCoder(in runtime: any Runtime) -> any CustomDynamicCoder
}

public extension RuntimeCustomDynamicCoder where Self: CustomDynamicCoder {
    func check(type: TypeDefinition, in runtime: any Runtime) -> Bool {
        check(type: type)
    }
}

public extension RuntimeCustomDynamicCoder {
    @inlinable
    func decode<D: ScaleCodec.Decoder>(
        from decoder: inout D, as type: TypeDefinition,
        in runtime: any Runtime
    ) throws -> Value<TypeDefinition> {
        if let dyn = self as? CustomDynamicCoder {
            return try dyn.decode(from: &decoder, as: type,
                                  with: runtime.dynamicCustomCoders)
        }
        return try Value(from: &decoder, as: type,
                         with: runtime.dynamicCustomCoders,
                         skip: true)
    }
    
    @inlinable
    func encode<C, E: ScaleCodec.Encoder>(
        value: Value<C>, in encoder: inout E,
        as type: TypeDefinition, in runtime: any Runtime
    ) throws {
        if let dyn = self as? CustomDynamicCoder {
            try dyn.encode(value: value, in: &encoder, as: type,
                           with: runtime.dynamicCustomCoders)
        } else {
            try value.encode(in: &encoder, as: type,
                             with: runtime.dynamicCustomCoders,
                             skip: true)
        }
    }
    
    @inlinable
    func decode(from container: inout ValueDecodingContainer,
                as type: TypeDefinition,
                in runtime: any Runtime) throws -> Value<TypeDefinition>
    {
        if let dyn = self as? CustomDynamicCoder {
            return try dyn.decode(from: &container, as: type,
                                  with: runtime.dynamicCustomCoders)
        }
        return try Value(from: &container, as: type,
                         runtime: runtime, skip: true)
    }
    
    @inlinable
    func validate<C>(value: Value<C>, as type: TypeDefinition,
                     in runtime: any Runtime) -> Result<Void, TypeError>
    {
        value.validate(as: type, in: runtime, skip: true)
    }
    
    @inlinable
    func dynamicCoder(in runtime: any Runtime) -> any CustomDynamicCoder {
        if let dyn = self as? CustomDynamicCoder {
            return dyn
        }
        return RuntimeCustomDynamicCoderWrapper(coder: self,
                                                runtime: runtime)
    }
}

public struct RuntimeCustomDynamicCoderWrapper: CustomDynamicCoder {
    public let coder: any RuntimeCustomDynamicCoder
    public private(set) weak var runtime: (any Runtime)!
    
    public init(coder: any RuntimeCustomDynamicCoder, runtime: any Runtime) {
        self.coder = coder
        self.runtime = runtime
    }
    
    public func check(type: TypeDefinition) -> Bool {
        coder.check(type: type, in: runtime)
    }
    
    public func decode<D: ScaleCodec.Decoder>(
        from decoder: inout D, as type: TypeDefinition,
        with coders: [ObjectIdentifier: any CustomDynamicCoder]?
    ) throws -> Value<TypeDefinition> {
        try coder.decode(from: &decoder, as: type, in: runtime)
    }
    
    public func encode<C, E: ScaleCodec.Encoder>(
        value: Value<C>, in encoder: inout E, as type: TypeDefinition,
        with coders: [ObjectIdentifier: any CustomDynamicCoder]?
    ) throws {
        try coder.encode(value: value, in: &encoder, as: type, in: runtime)
    }
    
    public func decode(from container: inout ValueDecodingContainer,
                       as type: TypeDefinition,
                       with coders: [ObjectIdentifier : CustomDynamicCoder]?
    ) throws -> Value<TypeDefinition> {
        try coder.decode(from: &container, as: type, in: runtime)
    }
}
