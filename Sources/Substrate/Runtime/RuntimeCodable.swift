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
                                `as` info: NetworkType.Info,
                                runtime: Runtime) throws
    {
        try self.init(from: &decoder, runtime: runtime)
    }
}

public extension RuntimeEncodable {
    @inlinable
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E,
                                       `as` info: NetworkType.Info,
                                       runtime: Runtime) throws
    {
        try self.encode(in: &encoder, runtime: runtime)
    }
}

public protocol RuntimeDynamicDecodable {
    init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                `as` id: NetworkType.Id,
                                runtime: Runtime) throws
    
    init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                `as` info: NetworkType.Info,
                                runtime: Runtime) throws
}

public protocol RuntimeDynamicEncodable {
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E,
                                       `as` id: NetworkType.Id,
                                       runtime: Runtime) throws
    
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E,
                                       `as` info: NetworkType.Info,
                                       runtime: Runtime) throws
}

public extension RuntimeDynamicDecodable {
    @inlinable
    init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                `as` id: NetworkType.Id,
                                runtime: Runtime) throws
    {
        guard let type = runtime.resolve(type: id) else {
            throw ScaleCodec.DecodingError.valueNotFound(
                NetworkType.Id.self,
                .init(path: decoder.path,
                      description: "Type \(id) is not found")
            )
        }
        try self.init(from: &decoder, as: id.i(type), runtime: runtime)
    }
}


public extension RuntimeDynamicEncodable {
    @inlinable
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E,
                                       `as` id: NetworkType.Id,
                                       runtime: Runtime) throws
    {
        guard let type = runtime.resolve(type: id) else {
            throw ScaleCodec.EncodingError.invalidValue(
                id, .init(path: encoder.path,
                          description: "Type not found in runtime")
            )
        }
        try encode(in: &encoder, as: id.i(type), runtime: runtime)
    }
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
        from decoder: inout D, type: T.Type, id: NetworkType.Id
    ) throws -> T {
        try T(from: &decoder, as: id, runtime: self)
    }
    
    @inlinable
    func decode<T: RuntimeDynamicDecodable, D: ScaleCodec.Decoder>(
        from decoder: inout D, type: T.Type, info: NetworkType.Info
    ) throws -> T {
        try T(from: &decoder, as: info, runtime: self)
    }
    
    @inlinable
    func decode<T: RuntimeDynamicDecodable, D: ScaleCodec.Decoder>(
        from decoder: inout D, id: NetworkType.Id
    ) throws -> T {
        try decode(from: &decoder, type: T.self, id: id)
    }
    
    @inlinable
    func decode<T: RuntimeDynamicDecodable, D: ScaleCodec.Decoder>(
        from decoder: inout D, info: NetworkType.Info
    ) throws -> T {
        try decode(from: &decoder, type: T.self, info: info)
    }
    
    @inlinable
    func decodeValue<D: ScaleCodec.Decoder>(
        from decoder: inout D, id: NetworkType.Id
    ) throws -> Value<NetworkType.Id> {
        try Value(from: &decoder, as: id, runtime: self)
    }
    
    @inlinable
    func decodeValue<D: ScaleCodec.Decoder>(
        from decoder: inout D, info: NetworkType.Info
    ) throws -> Value<NetworkType.Id> {
        try Value(from: &decoder, as: info, runtime: self)
    }
    
    @inlinable
    func decode<T: RuntimeDynamicDecodable, D: ScaleCodec.Decoder>(
        from decoder: inout D, type: T.Type,
        where id: NetworkType.LazyId
    ) throws -> T {
        switch type {
        case let type as ScaleCodec.Decodable.Type:
            return try type.init(from: &decoder) as! T
        case let type as RuntimeDecodable.Type:
            return try decode(from: &decoder, type) as! T
        default:
            return try decode(from: &decoder, type: type, id: id(self))
        }
    }
    
    @inlinable
    func decode<T: RuntimeDynamicDecodable, D: ScaleCodec.Decoder>(
        from decoder: inout D,
        where id: NetworkType.LazyId
    ) throws -> T {
        try decode(from: &decoder, type: T.self, where: id)
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
        from data: Data, type: T.Type, id: NetworkType.Id
    ) throws -> T {
        var decoder = decoder(with: data)
        return try decode(from: &decoder, type: type, id: id)
    }
    
    @inlinable
    func decode<T: RuntimeDynamicDecodable>(
        from data: Data, type: T.Type, info: NetworkType.Info
    ) throws -> T {
        var decoder = decoder(with: data)
        return try decode(from: &decoder, type: type, info: info)
    }
    
    @inlinable
    func decode<T: RuntimeDynamicDecodable>(
        from data: Data, id: NetworkType.Id
    ) throws -> T {
        try decode(from: data, type: T.self, id: id)
    }
    
    @inlinable
    func decode<T: RuntimeDynamicDecodable>(
        from data: Data, info: NetworkType.Info
    ) throws -> T {
        try decode(from: data, type: T.self, info: info)
    }
    
    @inlinable
    func decodeValue(from data: Data, id: NetworkType.Id) throws -> Value<NetworkType.Id> {
        var decoder = decoder(with: data)
        return try decodeValue(from: &decoder, id: id)
    }
    
    @inlinable
    func decodeValue(from data: Data, info: NetworkType.Info) throws -> Value<NetworkType.Id> {
        var decoder = decoder(with: data)
        return try decodeValue(from: &decoder, info: info)
    }
    
    @inlinable
    func decode<T: RuntimeDynamicDecodable>(
        from data: Data, type: T.Type,
        where id: NetworkType.LazyId
    ) throws -> T {
        var decoder = decoder(with: data)
        return try decode(from: &decoder, type: type, where: id)
    }
    
    @inlinable
    func decode<T: RuntimeDynamicDecodable>(
        from data: Data, where id: NetworkType.LazyId
    ) throws -> T {
        try decode(from: data, type: T.self, where: id)
    }
    
    @inlinable
    func encode<T: RuntimeEncodable, E: ScaleCodec.Encoder>(value: T, in encoder: inout E) throws {
        try value.encode(in: &encoder, runtime: self)
    }
    
    @inlinable
    func encode<T: RuntimeDynamicEncodable, E: ScaleCodec.Encoder>(
        value: T, in encoder: inout E, `as` id: NetworkType.Id
    ) throws {
        try value.encode(in: &encoder, as: id, runtime: self)
    }
    
    @inlinable
    func encode<T: RuntimeDynamicEncodable, E: ScaleCodec.Encoder>(
        value: T, in encoder: inout E, `as` info: NetworkType.Info
    ) throws {
        try value.encode(in: &encoder, as: info, runtime: self)
    }
    
    @inlinable
    func encode<T: RuntimeDynamicEncodable, E: ScaleCodec.Encoder>(
        value: T, in encoder: inout E, where id: NetworkType.LazyId
    ) throws {
        switch value {
        case let val as ScaleCodec.Encodable: try val.encode(in: &encoder)
        case let val as RuntimeEncodable: try encode(value: val, in: &encoder)
        default: try encode(value: value, in: &encoder, as: id(self))
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
        value: T, `as` id: NetworkType.Id
    ) throws -> Data {
        var encoder = encoder()
        try encode(value: value, in: &encoder, as: id)
        return encoder.output
    }
    
    @inlinable
    func encode<T: RuntimeDynamicEncodable>(
        value: T, `as` info: NetworkType.Info
    ) throws -> Data {
        var encoder = encoder()
        try encode(value: value, in: &encoder, as: info)
        return encoder.output
    }
    
    @inlinable
    func encode<T: RuntimeDynamicEncodable>(
        value: T, where id: NetworkType.LazyId
    ) throws -> Data {
        var encoder = encoder()
        try encode(value: value, in: &encoder, where: id)
        return encoder.output
    }
}

public protocol RuntimeCustomDynamicCoder {
    func checkType(info: NetworkType.Info, runtime: any Runtime) throws -> Bool
    
    func decode<D: ScaleCodec.Decoder>(
        from decoder: inout D, as info: NetworkType.Info, runtime: any Runtime
    ) throws -> Value<NetworkType.Id>
    
    func encode<C, E: ScaleCodec.Encoder>(
        value: Value<C>, in encoder: inout E, as info: NetworkType.Info, runtime: any Runtime
    ) throws
    
    func decode(from container: inout ValueDecodingContainer,
                as info: NetworkType.Info, runtime: any Runtime) throws -> Value<NetworkType.Id>
    
    func validate<C>(value: Value<C>, as info: NetworkType.Info,
                     runtime: any Runtime) -> Result<Void, TypeError>
}

public extension RuntimeCustomDynamicCoder {
    @inlinable
    func decode<D: ScaleCodec.Decoder>(
        from decoder: inout D, as info: NetworkType.Info, runtime: any Runtime
    ) throws -> Value<NetworkType.Id> {
        try Value(from: &decoder, as: info, runtime: runtime, custom: false)
    }
    
    @inlinable
    func encode<C, E: ScaleCodec.Encoder>(
        value: Value<C>, in encoder: inout E, as info: NetworkType.Info, runtime: any Runtime
    ) throws {
        try value.encode(in: &encoder, as: info, runtime: runtime, custom: false)
    }

    @inlinable
    func decode(from container: inout ValueDecodingContainer,
                as info: NetworkType.Info, runtime: any Runtime) throws -> Value<NetworkType.Id> {
        try Value(from: &container, as: info, runtime: runtime, custom: false)
    }
}
