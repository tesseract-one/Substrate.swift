//
//  RuntimeSwiftCodable.swift
//  
//
//  Created by Yehor Popovych on 06/07/2023.
//

import Foundation
import ContextCodable

public protocol SomeRuntimeDynamicSwiftCodableContext {
    init(runtime: any Runtime, type: @escaping TypeDefinition.Lazy) throws
}

public protocol SomeRuntimeSwiftCodableContext: SomeRuntimeDynamicSwiftCodableContext {
    init(runtime: any Runtime)
}

public struct VoidCodableContext: SomeRuntimeSwiftCodableContext {
    public init() {}
    public init(runtime: any Runtime) {}
    public init(runtime: any Runtime, type: @escaping TypeDefinition.Lazy) throws {}
}

public struct RuntimeCodableContext: SomeRuntimeSwiftCodableContext {
    public let runtime: any Runtime
    
    public init(runtime: any Runtime) {
        self.runtime = runtime
    }
    
    public init(runtime: any Runtime, type: @escaping TypeDefinition.Lazy) throws {
        self.runtime = runtime
    }
}

public struct RuntimeDynamicCodableContext: SomeRuntimeDynamicSwiftCodableContext {
    public let runtime: any Runtime
    public let type: TypeDefinition
    
    public init(runtime: any Runtime, type: @escaping TypeDefinition.Lazy) throws {
        try self.init(runtime: runtime, type: type())
    }
    
    public init(runtime: any Runtime, type: TypeDefinition) {
        self.runtime = runtime
        self.type = type
    }
}

public protocol RuntimeSwiftDecodable: ContextDecodable where
    DecodingContext: SomeRuntimeSwiftCodableContext
{
    init(from decoder: Decoder, runtime: any Runtime) throws
}

public protocol RuntimeSwiftEncodable: ContextEncodable where
    EncodingContext: SomeRuntimeSwiftCodableContext
{
    func encode(to encoder: Encoder, runtime: any Runtime) throws
}

public typealias RuntimeSwiftCodable = RuntimeSwiftDecodable & RuntimeSwiftEncodable

public protocol RuntimeDynamicSwiftDecodable: ContextDecodable where
    DecodingContext: SomeRuntimeDynamicSwiftCodableContext
{
    init(from decoder: Decoder, `as` type: TypeDefinition, runtime: Runtime) throws
}

public protocol RuntimeDynamicSwiftEncodable: ContextEncodable where
    EncodingContext: SomeRuntimeDynamicSwiftCodableContext
{
    func encode(to encoder: Encoder, `as` type: TypeDefinition, runtime: any Runtime) throws
}

public typealias RuntimeDynamicSwiftCodable = RuntimeDynamicSwiftDecodable & RuntimeDynamicSwiftEncodable

public extension Swift.Decodable {
    @inlinable
    init(from decoder: Decoder, runtime: any Runtime) throws {
        try self.init(from: decoder)
    }
    
    @inlinable
    init(from decoder: Decoder, `as` type: TypeDefinition, runtime: any Runtime) throws {
        try self.init(from: decoder)
    }
}

public extension Swift.Decodable where Self: ContextDecodable {
    init(from decoder: Decoder, context: DecodingContext) throws {
        try self.init(from: decoder)
    }
}

public extension Swift.Encodable {
    @inlinable
    func encode(to encoder: Encoder, runtime: any Runtime) throws {
        try encode(to: encoder)
    }
    
    @inlinable
    func encode(to encoder: Encoder, `as` type: TypeDefinition, runtime: any Runtime) throws {
        try encode(to: encoder)
    }
}

public extension Swift.Encodable where Self: ContextEncodable {
    func encode(to encoder: Encoder, context: EncodingContext) throws {
        try encode(to: encoder)
    }
}

public extension RuntimeSwiftDecodable where
    DecodingContext == RuntimeCodableContext
{
    @inlinable
    init(from decoder: Decoder, context: DecodingContext) throws {
        try self.init(from: decoder, runtime: context.runtime)
    }
    
    @inlinable
    init(from decoder: Decoder, `as` type: TypeDefinition, runtime: any Runtime) throws {
        try self.init(from: decoder, runtime: runtime)
    }
}

public extension RuntimeSwiftEncodable where
    EncodingContext == RuntimeCodableContext
{
    @inlinable
    func encode(to encoder: Encoder, context: EncodingContext) throws {
        try encode(to: encoder, runtime: context.runtime)
    }
    
    @inlinable
    func encode(to encoder: Encoder, `as` type: TypeDefinition, runtime: any Runtime) throws {
        try encode(to: encoder, runtime: runtime)
    }
}

public extension RuntimeDynamicSwiftDecodable where
    DecodingContext == RuntimeDynamicCodableContext
{
    @inlinable
    init(from decoder: Decoder, context: DecodingContext) throws {
        try self.init(from: decoder, as: context.type, runtime: context.runtime)
    }
}

public extension RuntimeDynamicSwiftEncodable where
    EncodingContext == RuntimeDynamicCodableContext
{
    @inlinable
    func encode(to encoder: Encoder, context: EncodingContext) throws {
        try encode(to: encoder, as: context.type, runtime: context.runtime)
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
