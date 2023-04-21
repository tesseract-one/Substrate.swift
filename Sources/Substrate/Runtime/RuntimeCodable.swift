//
//  RuntimeCodable.swift
//  
//
//  Created by Yehor Popovych on 05.01.2023.
//

import Foundation
import ScaleCodec

public protocol ScaleRuntimeEncodable {
    func encode(in encoder: ScaleEncoder, runtime: Runtime) throws
}

public protocol ScaleRuntimeDecodable {
    init(from decoder: ScaleDecoder, runtime: Runtime) throws
}

public typealias ScaleRuntimeCodable = ScaleRuntimeEncodable & ScaleRuntimeDecodable

public extension ScaleEncodable {
    func encode(in encoder: ScaleEncoder, runtime: Runtime) throws {
        try encode(in: encoder)
    }
}

public extension ScaleDecodable {
    init(from decoder: ScaleDecoder, runtime: Runtime) throws {
        try self.init(from: decoder)
    }
}

public extension ScaleRuntimeDecodable {
    init(from decoder: ScaleDecoder, `as` type: RuntimeTypeId, runtime: Runtime) throws {
        try self.init(from: decoder, runtime: runtime)
    }
}

public extension ScaleRuntimeEncodable {
    func encode(in encoder: ScaleEncoder, `as` type: RuntimeTypeId, runtime: Runtime) throws {
        try self.encode(in: encoder, runtime: runtime)
    }
}

public protocol ScaleRuntimeDynamicEncodable {
    func encode(in encoder: ScaleEncoder, `as` type: RuntimeTypeId, runtime: Runtime) throws
}

public protocol ScaleRuntimeDynamicDecodable {
    init(from decoder: ScaleDecoder, `as` type: RuntimeTypeId, runtime: Runtime) throws
}

public extension ScaleRuntimeDynamicEncodable {
    func encode(
        in encoder: ScaleEncoder, runtime: Runtime,
        where id: @escaping(Runtime) throws -> RuntimeTypeId
    ) throws {
        switch self {
        case let sself as ScaleEncodable: try sself.encode(in: encoder)
        case let sself as ScaleRuntimeEncodable: try sself.encode(in: encoder, runtime: runtime)
        default: try self.encode(in: encoder, as: id(runtime), runtime: runtime)
        }
    }
}

public extension ScaleRuntimeDynamicDecodable {
    init(
        from decoder: ScaleDecoder, runtime: Runtime,
        where id: @escaping(Runtime) throws -> RuntimeTypeId
    ) throws {
        switch Self.self {
        case let sself as ScaleDecodable.Type:
            self = try sself.init(from: decoder) as! Self
        case let sself as ScaleRuntimeDecodable.Type:
            self = try sself.init(from: decoder, runtime: runtime) as! Self
        default: try self.init(from: decoder, as: id(runtime), runtime: runtime)
        }
    }
}

public protocol RuntimeDynamicDecodable {
    init(from decoder: Decoder, `as` type: RuntimeTypeId) throws
}

public extension RuntimeDynamicDecodable {
    init(
        from decoder: Decoder,
        where id: @escaping(Runtime) throws -> RuntimeTypeId
    ) throws {
        switch Self.self {
        case let sself as Decodable.Type:
            self = try sself.init(from: decoder) as! Self
        default: try self.init(from: decoder, as: id(decoder.runtime))
        }
    }
}

public extension Decodable {
    init(from decoder: Decoder, `as` type: RuntimeTypeId) throws {
        try self.init(from: decoder)
    }
}

public extension Runtime {
    func decode<T: ScaleRuntimeDecodable>(from decoder: ScaleDecoder, type: T.Type) throws -> T {
        try T(from: decoder, runtime: self)
    }
    
    func decode<T: ScaleRuntimeDynamicDecodable>(
        from decoder: ScaleDecoder, type: T.Type, id: RuntimeTypeId
    ) throws -> T {
        try T(from: decoder, as: id, runtime: self)
    }
    
    func decode(from decoder: ScaleDecoder, type: RuntimeTypeId) throws -> Value<RuntimeTypeId> {
        try Value(from: decoder, as: type, runtime: self)
    }
    
    func decode<T: ScaleRuntimeDynamicDecodable>(
        from decoder: ScaleDecoder, type: T.Type,
        where id: @escaping(Runtime) throws -> RuntimeTypeId
    ) throws -> T {
        try T(from: decoder, runtime: self, where: id)
    }
}

public extension Runtime {
    func decode<T: Decodable>(from decoder: Decoder, type: T.Type) throws -> T {
        try T(from: decoder)
    }
    
    func decode<T: RuntimeDynamicDecodable>(
        from decoder: Decoder, type: T.Type, id: RuntimeTypeId
    ) throws -> T {
        try T(from: decoder, as: id)
    }
    
    func decode<T: Decodable>(
        from decoder: Decoder, type: T.Type,
        where id: @escaping(Runtime) throws -> RuntimeTypeId
    ) throws -> T {
        try T(from: decoder)
    }
    
    func decode(from decoder: Decoder, type: RuntimeTypeId) throws -> Value<RuntimeTypeId> {
        try Value(from: decoder, as: type)
    }
    
    func decode(from container: inout ValueDecodingContainer, type: RuntimeTypeId) throws -> Value<RuntimeTypeId> {
        try Value(from: &container, as: type, runtime: self)
    }
    
    func decode<T: RuntimeDynamicDecodable>(
        from decoder: Decoder, type: T.Type,
        where id: @escaping(Runtime) throws -> RuntimeTypeId
    ) throws -> T {
        try T(from: decoder, where: id)
    }
}
