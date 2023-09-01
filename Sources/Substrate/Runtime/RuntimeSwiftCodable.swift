//
//  RuntimeSwiftCodable.swift
//  
//
//  Created by Yehor Popovych on 06/07/2023.
//

import Foundation
import ContextCodable

public protocol SomeRuntimeDynamicSwiftCodableContext {
    var runtime: Runtime { get }
    var type: RuntimeType.LazyId { get }
    
    init(runtime: Runtime, type: @escaping RuntimeType.LazyId)
}

public struct RuntimeSwiftCodableContext: SomeRuntimeDynamicSwiftCodableContext {
    public var runtime: Runtime
    public var type: RuntimeType.LazyId
    
    public init(runtime: Runtime, type: @escaping RuntimeType.LazyId) {
        self.runtime = runtime
        self.type = type
    }
    
    public init(runtime: Runtime) {
        self.runtime = runtime
        self.type = RuntimeType.IdNever
    }
}

public struct RuntimeDynamicSwiftCodableContext: SomeRuntimeDynamicSwiftCodableContext {
    public let runtime: Runtime
    public let type: RuntimeType.LazyId
    
    public init(runtime: Runtime, type: @escaping RuntimeType.LazyId) {
        self.runtime = runtime
        self.type = type
    }
}

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
    DecodingContext: SomeRuntimeDynamicSwiftCodableContext
{
    init(from decoder: Decoder, `as` type: RuntimeType.Id, runtime: Runtime) throws
}

public protocol RuntimeDynamicSwiftEncodable: ContextEncodable where
    EncodingContext: SomeRuntimeDynamicSwiftCodableContext
{
    func encode(to encoder: Encoder, `as` type: RuntimeType.Id, runtime: any Runtime) throws
}

public typealias RuntimeDynamicSwiftCodable = RuntimeDynamicSwiftDecodable & RuntimeDynamicSwiftEncodable

public extension Swift.Decodable {
    @inlinable
    init(from decoder: Decoder, runtime: any Runtime) throws {
        try self.init(from: decoder)
    }
}

public extension Swift.Encodable {
    @inlinable
    func encode(to encoder: Encoder, runtime: any Runtime) throws {
        try encode(to: encoder)
    }
}

public extension RuntimeSwiftDecodable {
    @inlinable
    init(from decoder: Decoder, context: DecodingContext) throws {
        try self.init(from: decoder, runtime: context.runtime)
    }
}

public extension RuntimeSwiftDecodable where
    DecodingContext == RuntimeSwiftCodableContext
{
    @inlinable
    init(from decoder: Decoder, `as` type: RuntimeType.Id, runtime: Runtime) throws {
        try self.init(from: decoder, runtime: runtime)
    }
}

public extension RuntimeSwiftEncodable {
    @inlinable
    func encode(to encoder: Encoder, context: EncodingContext) throws {
        try encode(to: encoder, runtime: context.runtime)
    }
    
    @inlinable
    func encode(to encoder: Encoder, `as` type: RuntimeType.Id, runtime: any Runtime) throws {
        try encode(to: encoder, runtime: runtime)
    }
}

public extension RuntimeDynamicSwiftDecodable where
    DecodingContext == RuntimeDynamicSwiftCodableContext
{
    @inlinable
    init(from decoder: Decoder, context: DecodingContext) throws {
        try self.init(from: decoder, runtime: context.runtime, id: context.type)
    }
}

public extension RuntimeDynamicSwiftDecodable {
    @inlinable
    init(from decoder: Decoder, runtime: any Runtime,
         id: RuntimeType.LazyId) throws
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

public extension RuntimeDynamicSwiftEncodable where
    EncodingContext == RuntimeDynamicSwiftCodableContext
{
    @inlinable
    func encode(to encoder: Encoder, context: EncodingContext) throws {
        try encode(to: encoder, runtime: context.runtime, id: context.type)
    }
}

public extension RuntimeDynamicSwiftEncodable {
    @inlinable
    func encode(to encoder: Encoder, runtime: any Runtime,
                id: RuntimeType.LazyId) throws
    {
        switch self {
        case let sself as Swift.Encodable: try sself.encode(to: encoder)
        case let sself as any RuntimeSwiftEncodable: try sself.encode(to: encoder, runtime: runtime)
        default: try self.encode(to: encoder, as: id(runtime), runtime: runtime)
        }
    }
}

public extension CaseIterable where Self: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let name = try container.decode(String.self)
        guard let cs = Self.allCases.first(
            where: { name == String(describing: $0).uppercasedFirst }
        ) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: container.codingPath,
                      debugDescription: "Unknown enum case \(name) for \(Self.self)")
            )
        }
        self = cs
    }
}

public extension CaseIterable where Self: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(String(describing: self).uppercasedFirst)
    }
}
