//
//  RuntimeSwiftCodable.swift
//  
//
//  Created by Yehor Popovych on 06/07/2023.
//

import Foundation
import ContextCodable

public typealias RuntimeSwiftCodableContext = Runtime
public typealias RuntimeDynamicSwiftCodableContext = (runtime: Runtime, type: (Runtime) throws -> RuntimeTypeId)

public protocol RuntimeSwiftDecodable: ContextDecodable where
    DecodingContext == RuntimeSwiftCodableContext
{
    init(from decoder: Decoder, runtime: any Runtime) throws
}

public protocol RuntimeSwiftEncodable: ContextEncodable where
    EncodingContext == RuntimeSwiftCodableContext
{
    func encode(to encoder: Encoder, runtime: any Runtime) throws
}

public typealias RuntimeSwiftCodable = RuntimeSwiftDecodable & RuntimeSwiftEncodable

public protocol RuntimeDynamicSwiftDecodable: ContextDecodable where
    DecodingContext == RuntimeDynamicSwiftCodableContext
{
    init(from decoder: Decoder, `as` type: RuntimeTypeId, runtime: Runtime) throws
}

public protocol RuntimeDynamicSwiftEncodable: ContextEncodable where
    EncodingContext == RuntimeDynamicSwiftCodableContext
{
    func encode(to encoder: Encoder, `as` type: RuntimeTypeId, runtime: any Runtime) throws
}

public extension Swift.Decodable {
    @inlinable
    init(from decoder: Decoder, runtime: any Runtime) throws {
        try self.init(from: decoder)
    }
}

public extension Swift.Encodable {
    @inlinable
    func encode(to encoder: Encoder, runtime: any Runtime) throws {
        try self.encode(to: encoder)
    }
}

public extension RuntimeSwiftDecodable {
    @inlinable
    init(from decoder: Decoder, context: DecodingContext) throws {
        try self.init(from: decoder, runtime: context)
    }
    
    @inlinable
    init(from decoder: Decoder, `as` type: RuntimeTypeId, runtime: Runtime) throws {
        try self.init(from: decoder, runtime: runtime)
    }
}

public extension RuntimeSwiftEncodable {
    @inlinable
    func encode(to encoder: Encoder, context: EncodingContext) throws {
        try encode(to: encoder, runtime: context)
    }
    
    @inlinable
    func encode(to encoder: Encoder, `as` type: RuntimeTypeId, runtime: any Runtime) throws {
        try encode(to: encoder, runtime: runtime)
    }
}

public extension RuntimeDynamicSwiftDecodable {
    @inlinable
    init(from decoder: Decoder, context: DecodingContext) throws {
        try self.init(from: decoder, runtime: context.runtime, where: context.type)
    }
    
    @inlinable
    init(from decoder: Decoder, runtime: any Runtime,
         where id: @escaping(Runtime) throws -> RuntimeTypeId) throws
    {
        switch Self.self {
        case let sself as Swift.Decodable.Type:
            self = try sself.init(from: decoder) as! Self
        case let sself as any RuntimeSwiftDecodable.Type:
            self = try sself.init(from: decoder, runtime: runtime) as! Self
        default: try self.init(from: decoder, as: id(runtime), runtime: runtime)
        }
    }
}

public extension RuntimeDynamicSwiftEncodable {
    @inlinable
    func encode(to encoder: Encoder, context: EncodingContext) throws {
        try encode(to: encoder, runtime: context.runtime, where: context.type)
    }
    
    @inlinable
    func encode(to encoder: Encoder, runtime: any Runtime,
                where id: @escaping(Runtime) throws -> RuntimeTypeId) throws
    {
        switch self {
        case let sself as Swift.Encodable: try sself.encode(to: encoder)
        case let sself as any RuntimeSwiftEncodable: try sself.encode(to: encoder, runtime: runtime)
        default: try self.encode(to: encoder, as: id(runtime), runtime: runtime)
        }
    }
}
