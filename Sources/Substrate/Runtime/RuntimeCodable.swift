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
                                `as` type: RuntimeType.Id,
                                runtime: Runtime) throws
    {
        try self.init(from: &decoder, runtime: runtime)
    }
}

public extension RuntimeEncodable {
    @inlinable
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E,
                                       `as` type: RuntimeType.Id,
                                       runtime: Runtime) throws
    {
        try self.encode(in: &encoder, runtime: runtime)
    }
}

public protocol RuntimeDynamicEncodable {
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E,
                                       `as` type: RuntimeType.Id,
                                       runtime: Runtime) throws
}

public protocol RuntimeDynamicDecodable {
    init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                `as` type: RuntimeType.Id,
                                runtime: Runtime) throws
}

public typealias RuntimeDynamicCodable = RuntimeDynamicDecodable & RuntimeDynamicEncodable

public extension RuntimeDynamicEncodable {
    @inlinable
    func encode<E: ScaleCodec.Encoder>(
        in encoder: inout E, runtime: Runtime,
        id: @escaping RuntimeType.LazyId
    ) throws {
        switch self {
        case let sself as ScaleCodec.Encodable: try sself.encode(in: &encoder)
        case let sself as RuntimeEncodable: try sself.encode(in: &encoder, runtime: runtime)
        default: try self.encode(in: &encoder, as: id(runtime), runtime: runtime)
        }
    }
}

public extension RuntimeDynamicDecodable {
    @inlinable
    init<D: ScaleCodec.Decoder>(
        from decoder: inout D, runtime: Runtime,
        id: @escaping RuntimeType.LazyId
    ) throws {
        switch Self.self {
        case let sself as ScaleCodec.Decodable.Type:
            self = try sself.init(from: &decoder) as! Self
        case let sself as RuntimeDecodable.Type:
            self = try sself.init(from: &decoder, runtime: runtime) as! Self
        default: try self.init(from: &decoder, as: id(runtime), runtime: runtime)
        }
    }
}

public extension Runtime {
    @inlinable
    func decode<T: RuntimeDecodable, D: ScaleCodec.Decoder>(from decoder: inout D, type: T.Type) throws -> T {
        try T(from: &decoder, runtime: self)
    }
    
    @inlinable
    func decode<T: RuntimeDecodable, D: ScaleCodec.Decoder>(from decoder: inout D) throws -> T {
        try decode(from: &decoder, type: T.self)
    }
    
    @inlinable
    func decode<T: RuntimeDynamicDecodable, D: ScaleCodec.Decoder>(
        from decoder: inout D, type: T.Type, id: RuntimeType.Id
    ) throws -> T {
        try T(from: &decoder, as: id, runtime: self)
    }
    
    @inlinable
    func decode<T: RuntimeDynamicDecodable, D: ScaleCodec.Decoder>(
        from decoder: inout D, id: RuntimeType.Id
    ) throws -> T {
        try decode(from: &decoder, type: T.self, id: id)
    }
    
    @inlinable
    func decodeValue<D: ScaleCodec.Decoder>(
        from decoder: inout D, id: RuntimeType.Id
    ) throws -> Value<RuntimeType.Id> {
        try Value(from: &decoder, as: id, runtime: self)
    }
    
    @inlinable
    func decode<T: RuntimeDynamicDecodable, D: ScaleCodec.Decoder>(
        from decoder: inout D, type: T.Type,
        where id: @escaping RuntimeType.LazyId
    ) throws -> T {
        try T(from: &decoder, runtime: self, id: id)
    }
    
    @inlinable
    func decode<T: RuntimeDynamicDecodable, D: ScaleCodec.Decoder>(
        from decoder: inout D,
        where id: @escaping RuntimeType.LazyId
    ) throws -> T {
        try decode(from: &decoder, type: T.self, where: id)
    }
    
    @inlinable
    func decode<T: RuntimeDecodable>(from data: Data, _ type: T.Type) throws -> T {
        var decoder = decoder(with: data)
        return try decode(from: &decoder, type: type)
    }
    
    @inlinable
    func decode<T: RuntimeDecodable>(from data: Data) throws -> T {
        try decode(from: data, T.self)
    }
    
    @inlinable
    func decode<T: RuntimeDynamicDecodable>(
        from data: Data, type: T.Type, id: RuntimeType.Id
    ) throws -> T {
        var decoder = decoder(with: data)
        return try decode(from: &decoder, type: type, id: id)
    }
    
    @inlinable
    func decode<T: RuntimeDynamicDecodable>(
        from data: Data, id: RuntimeType.Id
    ) throws -> T {
        try decode(from: data, type: T.self, id: id)
    }
    
    @inlinable
    func decodeValue(from data: Data, id: RuntimeType.Id) throws -> Value<RuntimeType.Id> {
        var decoder = decoder(with: data)
        return try decodeValue(from: &decoder, id: id)
    }
    
    @inlinable
    func decode<T: RuntimeDynamicDecodable>(
        from data: Data, type: T.Type,
        where id: @escaping RuntimeType.LazyId
    ) throws -> T {
        var decoder = decoder(with: data)
        return try decode(from: &decoder, type: type, where: id)
    }
    
    @inlinable
    func decode<T: RuntimeDynamicDecodable>(
        from data: Data, where id: @escaping RuntimeType.LazyId
    ) throws -> T {
        try decode(from: data, type: T.self, where: id)
    }
    
    @inlinable
    func encode<T: RuntimeEncodable>(value: T) throws -> Data {
        var encoder = encoder()
        try value.encode(in: &encoder, runtime: self)
        return encoder.output
    }
    
    @inlinable
    func encode<T: RuntimeDynamicEncodable>(
        value: T, `as` id: RuntimeType.Id
    ) throws -> Data {
        var encoder = encoder()
        try value.encode(in: &encoder, as: id, runtime: self)
        return encoder.output
    }
    
    @inlinable
    func encode<T: RuntimeDynamicEncodable>(
        value: T, where id: @escaping RuntimeType.LazyId
    ) throws -> Data {
        var encoder = encoder()
        try value.encode(in: &encoder, runtime: self, id: id)
        return encoder.output
    }
}
