//
//  RuntimeCodable.swift
//  
//
//  Created by Yehor Popovych on 05.01.2023.
//

import Foundation
import ScaleCodec

public protocol RuntimeEncodable {
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws
}

public protocol RuntimeDecodable {
    init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws
}

public typealias RuntimeCodable = RuntimeEncodable & RuntimeDecodable

public extension ScaleCodec.Encodable {
    @inlinable
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
        try encode(in: &encoder)
    }
}

public extension ScaleCodec.Decodable {
    @inlinable
    init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws {
        try self.init(from: &decoder)
    }
}

public extension RuntimeDecodable {
    @inlinable
    init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                `as` type: TypeDefinition,
                                runtime: any Runtime) throws
    {
        try self.init(from: &decoder, runtime: runtime)
    }
}

public extension RuntimeEncodable {
    @inlinable
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E,
                                       `as` type: TypeDefinition,
                                       runtime: any Runtime) throws
    {
        try self.encode(in: &encoder, runtime: runtime)
    }
}

public protocol RuntimeDynamicDecodable {
    init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                `as` type: TypeDefinition,
                                runtime: any Runtime) throws
}

public protocol RuntimeDynamicEncodable {
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E,
                                       `as` type: TypeDefinition,
                                       runtime: Runtime) throws
}

public typealias RuntimeDynamicCodable = RuntimeDynamicDecodable & RuntimeDynamicEncodable

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
    func decode<T: RuntimeDynamicDecodable, D: ScaleCodec.Decoder>(
        from decoder: inout D, type: T.Type,
        where def: TypeDefinition.Lazy
    ) throws -> T {
        switch type {
        case let type as ScaleCodec.Decodable.Type:
            return try type.init(from: &decoder) as! T
        case let type as RuntimeDecodable.Type:
            return try decode(from: &decoder, type) as! T
        default:
            return try decode(from: &decoder, type: type, def: def())
        }
    }
    
    @inlinable
    func decode<T: RuntimeDynamicDecodable, D: ScaleCodec.Decoder>(
        from decoder: inout D,
        where type: TypeDefinition.Lazy
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
    func decode<T: RuntimeDynamicDecodable>(
        from data: Data, type: T.Type,
        where def: TypeDefinition.Lazy
    ) throws -> T {
        var decoder = decoder(with: data)
        return try decode(from: &decoder, type: type, where: def)
    }
    
    @inlinable
    func decode<T: RuntimeDynamicDecodable>(
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
    func encode<T: RuntimeDynamicEncodable, E: ScaleCodec.Encoder>(
        value: T, in encoder: inout E, where type: TypeDefinition.Lazy
    ) throws {
        switch value {
        case let val as ScaleCodec.Encodable: try val.encode(in: &encoder)
        case let val as RuntimeEncodable: try encode(value: val, in: &encoder)
        default: try encode(value: value, in: &encoder, as: type())
        }
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
    func encode<T: RuntimeDynamicEncodable>(
        value: T, where type: TypeDefinition.Lazy
    ) throws -> Data {
        var encoder = encoder()
        try encode(value: value, in: &encoder, where: type)
        return encoder.output
    }
}

public protocol RuntimeCustomDynamicCoder: CustomDynamicCoder {
    func decode(from container: inout ValueDecodingContainer,
                as type: TypeDefinition,
                in runtime: any Runtime) throws -> Value<TypeDefinition>
    
    func validate<C>(value: Value<C>, as type: TypeDefinition,
                     in runtime: any Runtime) -> Result<Void, TypeError>
}

public extension RuntimeCustomDynamicCoder {
    @inlinable
    func decode(from container: inout ValueDecodingContainer,
                as type: TypeDefinition,
                in runtime: any Runtime) throws -> Value<TypeDefinition>
    {
        try Value(from: &container, as: type, runtime: runtime, skip: true)
    }
    
    @inlinable
    func validate<C>(value: Value<C>, as type: TypeDefinition,
                     in runtime: any Runtime) -> Result<Void, TypeError>
    {
        value.validate(as: type, in: runtime, skip: true)
    }
}
