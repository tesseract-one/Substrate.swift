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

public protocol SwiftRuntimeDynamicDecodable {
    init(from decoder: Swift.Decoder, `as` type: RuntimeTypeId) throws
}

public extension SwiftRuntimeDynamicDecodable {
    init(
        from decoder: Swift.Decoder,
        where id: @escaping(Runtime) throws -> RuntimeTypeId
    ) throws {
        switch Self.self {
        case let sself as Swift.Decodable.Type:
            self = try sself.init(from: decoder) as! Self
        default: try self.init(from: decoder, as: id(decoder.runtime))
        }
    }
}

public extension Swift.Decodable {
    init(from decoder: Swift.Decoder, `as` type: RuntimeTypeId) throws {
        try self.init(from: decoder)
    }
}

public extension Runtime {
    func decode<T: RuntimeDecodable, D: ScaleCodec.Decoder>(from decoder: inout D, type: T.Type) throws -> T {
        try T(from: &decoder, runtime: self)
    }
    
    func decode<T: RuntimeDynamicDecodable, D: ScaleCodec.Decoder>(
        from decoder: inout D, type: T.Type, id: RuntimeTypeId
    ) throws -> T {
        try T(from: &decoder, as: id, runtime: self)
    }
    
    func decode<D: ScaleCodec.Decoder>(from decoder: inout D, type: RuntimeTypeId) throws -> Value<RuntimeTypeId> {
        try Value(from: &decoder, as: type, runtime: self)
    }
    
    func decode<T: RuntimeDynamicDecodable, D: ScaleCodec.Decoder>(
        from decoder: inout D, type: T.Type,
        where id: @escaping(Runtime) throws -> RuntimeTypeId
    ) throws -> T {
        try T(from: &decoder, runtime: self, where: id)
    }
}

// Swift Decodable
public extension Runtime {
    func decode<T: Swift.Decodable>(from decoder: Swift.Decoder, type: T.Type) throws -> T {
        try T(from: decoder)
    }
    
    func decode<T: Swift.Decodable>(
        from decoder: Swift.Decoder, type: T.Type,
        where id: @escaping(Runtime) throws -> RuntimeTypeId
    ) throws -> T {
        try T(from: decoder)
    }
    
    func decode(from decoder: Swift.Decoder, type: RuntimeTypeId) throws -> Value<RuntimeTypeId> {
        try Value(from: decoder, as: type)
    }
    
    func decode(from container: inout ValueDecodingContainer, type: RuntimeTypeId) throws -> Value<RuntimeTypeId> {
        try Value(from: &container, as: type, runtime: self)
    }
    
    func decode<T: SwiftRuntimeDynamicDecodable>(
        from decoder: Swift.Decoder, type: T.Type,
        where id: @escaping(Runtime) throws -> RuntimeTypeId
    ) throws -> T {
        try T(from: decoder, where: id)
    }
}
