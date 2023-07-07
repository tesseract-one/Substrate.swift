//
//  RuntimeSwiftCodable.swift
//  
//
//  Created by Yehor Popovych on 06/07/2023.
//

import Foundation
import ContextCodable

public protocol RuntimeSwiftDecodable {
    init(from decoder: Decoder, runtime: Runtime) throws
}

public extension RuntimeSwiftDecodable where Self: ContextDecodable, DecodingContext == Runtime {
    @inlinable
    init(from decoder: Decoder, context: DecodingContext) throws {
        try self.init(from: decoder, runtime: context)
    }
}

public protocol RuntimeSwiftEncodable {
    func encode(to encoder: Encoder, runtime: any Runtime) throws
}

public extension RuntimeSwiftEncodable where Self: ContextEncodable, EncodingContext == Runtime {
    @inlinable
    func encode(to encoder: Encoder, context: EncodingContext) throws {
        try encode(to: encoder, runtime: context)
    }
}

public protocol RuntimeDynamicSwiftDecodable {
    init(from decoder: Decoder, `as` type: RuntimeTypeId, runtime: Runtime) throws
}

public extension RuntimeDynamicSwiftDecodable where
    Self: ContextDecodable,
    DecodingContext == (type: (Runtime) throws -> RuntimeTypeId, runtime: Runtime)
{
    @inlinable
    init(from decoder: Decoder, context: DecodingContext) throws {
        switch Self.self {
        case let sself as Swift.Decodable.Type:
            self = try sself.init(from: decoder) as! Self
        case let sself as RuntimeSwiftDecodable.Type:
            self = try sself.init(from: decoder, runtime: context.runtime) as! Self
        default: try self.init(from: decoder,
                               as: context.type(context.runtime),
                               runtime: context.runtime)
        }
    }
}

public protocol RuntimeDynamicSwiftEncodable {
    func encode(to encoder: Encoder, `as` type: RuntimeTypeId, runtime: any Runtime) throws
}

public extension RuntimeDynamicSwiftEncodable where
    Self: ContextEncodable,
    EncodingContext == (type: (Runtime) throws -> RuntimeTypeId, runtime: Runtime)
{
    @inlinable
    func encode(to encoder: Encoder, context: EncodingContext) throws {
        switch self {
        case let sself as Swift.Encodable: try sself.encode(to: encoder)
        case let sself as RuntimeSwiftEncodable: try sself.encode(to: encoder, runtime: context.runtime)
        default: try self.encode(to: encoder,
                                 as: context.type(context.runtime),
                                 runtime: context.runtime)
        }
    }
}
