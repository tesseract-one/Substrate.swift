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
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
        try encode(in: &encoder)
    }
}

public extension ScaleCodec.Decodable {
    init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws {
        try self.init(from: &decoder)
    }
}

public extension RuntimeDecodable {
    init<D: ScaleCodec.Decoder>(from decoder: inout D, `as` type: RuntimeTypeId, runtime: Runtime) throws {
        try self.init(from: &decoder, runtime: runtime)
    }
}

public extension RuntimeEncodable {
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E, `as` type: RuntimeTypeId, runtime: Runtime) throws {
        try self.encode(in: &encoder, runtime: runtime)
    }
}

public protocol RuntimeDynamicEncodable {
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E, `as` type: RuntimeTypeId, runtime: Runtime) throws
}

public protocol RuntimeDynamicDecodable {
    init<D: ScaleCodec.Decoder>(from decoder: inout D, `as` type: RuntimeTypeId, runtime: Runtime) throws
}

public extension RuntimeDynamicEncodable {
    func encode<E: ScaleCodec.Encoder>(
        in encoder: inout E, runtime: Runtime,
        where id: @escaping(Runtime) throws -> RuntimeTypeId
    ) throws {
        switch self {
        case let sself as ScaleCodec.Encodable: try sself.encode(in: &encoder)
        case let sself as RuntimeEncodable: try sself.encode(in: &encoder, runtime: runtime)
        default: try self.encode(in: &encoder, as: id(runtime), runtime: runtime)
        }
    }
}

public extension RuntimeDynamicDecodable {
    init<D: ScaleCodec.Decoder>(
        from decoder: inout D, runtime: Runtime,
        where id: @escaping(Runtime) throws -> RuntimeTypeId
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
    func decode<T: RuntimeDecodable, D: ScaleCodec.Decoder>(from decoder: inout D, type: T.Type) throws -> T {
        try T(from: &decoder, runtime: self)
    }
    
    func decode<T: RuntimeDecodable, D: ScaleCodec.Decoder>(from decoder: inout D) throws -> T {
        try decode(from: &decoder, type: T.self)
    }
    
    func decode<T: RuntimeDynamicDecodable, D: ScaleCodec.Decoder>(
        from decoder: inout D, type: T.Type, id: RuntimeTypeId
    ) throws -> T {
        try T(from: &decoder, as: id, runtime: self)
    }
    
    func decode<T: RuntimeDynamicDecodable, D: ScaleCodec.Decoder>(
        from decoder: inout D, id: RuntimeTypeId
    ) throws -> T {
        try decode(from: &decoder, type: T.self, id: id)
    }
    
    func decodeValue<D: ScaleCodec.Decoder>(from decoder: inout D, id: RuntimeTypeId) throws -> Value<RuntimeTypeId> {
        try Value(from: &decoder, as: id, runtime: self)
    }
    
    func decode<T: RuntimeDynamicDecodable, D: ScaleCodec.Decoder>(
        from decoder: inout D, type: T.Type,
        where id: @escaping(Runtime) throws -> RuntimeTypeId
    ) throws -> T {
        try T(from: &decoder, runtime: self, where: id)
    }
    
    func decode<T: RuntimeDynamicDecodable, D: ScaleCodec.Decoder>(
        from decoder: inout D,
        where id: @escaping(Runtime) throws -> RuntimeTypeId
    ) throws -> T {
        try decode(from: &decoder, type: T.self, where: id)
    }
    
    func decode<T: RuntimeDecodable>(from data: Data, _ type: T.Type) throws -> T {
        var decoder = decoder(with: data)
        return try decode(from: &decoder, type: type)
    }
    
    func decode<T: RuntimeDecodable>(from data: Data) throws -> T {
        try decode(from: data, T.self)
    }
    
    func decode<T: RuntimeDynamicDecodable>(
        from data: Data, type: T.Type, id: RuntimeTypeId
    ) throws -> T {
        var decoder = decoder(with: data)
        return try decode(from: &decoder, type: type, id: id)
    }
    
    func decode<T: RuntimeDynamicDecodable>(
        from data: Data, id: RuntimeTypeId
    ) throws -> T {
        try decode(from: data, type: T.self, id: id)
    }
    
    func decodeValue(from data: Data, id: RuntimeTypeId) throws -> Value<RuntimeTypeId> {
        var decoder = decoder(with: data)
        return try decodeValue(from: &decoder, id: id)
    }
    
    func decode<T: RuntimeDynamicDecodable>(
        from data: Data, type: T.Type,
        where id: @escaping(Runtime) throws -> RuntimeTypeId
    ) throws -> T {
        var decoder = decoder(with: data)
        return try decode(from: &decoder, type: type, where: id)
    }
    
    func decode<T: RuntimeDynamicDecodable>(
        from data: Data, where id: @escaping(Runtime) throws -> RuntimeTypeId
    ) throws -> T {
        try decode(from: data, type: T.self, where: id)
    }
    
    func encode<T: RuntimeEncodable>(value: T) throws -> Data {
        var encoder = encoder()
        try value.encode(in: &encoder, runtime: self)
        return encoder.output
    }
    
    func encode<T: RuntimeDynamicEncodable>(value: T, `as` id: RuntimeTypeId) throws -> Data {
        var encoder = encoder()
        try value.encode(in: &encoder, as: id, runtime: self)
        return encoder.output
    }
    
    func encode<T: RuntimeDynamicEncodable>(
        value: T, where id: @escaping(Runtime) throws -> RuntimeTypeId
    ) throws -> Data {
        var encoder = encoder()
        try value.encode(in: &encoder, runtime: self, where: id)
        return encoder.output
    }
}
