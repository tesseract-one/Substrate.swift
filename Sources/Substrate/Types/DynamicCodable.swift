//
//  DynamicCodable.swift
//  
//
//  Created by Yehor Popovych on 11/09/2023.
//

import Foundation
import ScaleCodec
import ContextCodable

public protocol DynamicDecodable: RuntimeDynamicDecodable {
    init<D: ScaleCodec.Decoder>(from decoder: inout D, as type: TypeDefinition) throws
}

public protocol DynamicEncodable: RuntimeDynamicEncodable {
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E, `as` type: TypeDefinition) throws
}

public typealias DynamicCodable = DynamicDecodable & DynamicEncodable

public extension DynamicDecodable {
    @inlinable
    init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                `as` type: TypeDefinition,
                                runtime: any Runtime) throws
    {
        try self.init(from: &decoder, as: type)
    }
}

public extension DynamicEncodable {
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E,
                                       `as` type: TypeDefinition,
                                       runtime: Runtime) throws
    {
        try encode(in: &encoder, as: type)
    }
}

public protocol SomeDynamicSwiftCodableContext: SomeRuntimeDynamicSwiftCodableContext {
    init(type: TypeDefinition)
}

public struct DynamicCodableContext: SomeDynamicSwiftCodableContext {
    public let type: TypeDefinition
    
    public init(type: TypeDefinition) {
        self.type = type
    }
    
    public init(runtime: any Runtime, type: @escaping TypeDefinition.Lazy) throws {
        self.type = try type()
    }
}

extension VoidCodableContext: SomeDynamicSwiftCodableContext {
    @inlinable
    public init(type: TypeDefinition) { self.init() }
}

public protocol DynamicSwiftDecodable: ContextDecodable where
    DecodingContext: SomeDynamicSwiftCodableContext
{
    init(from decoder: Swift.Decoder, `as` type: TypeDefinition) throws
}

public protocol DynamicSwiftEncodable: ContextEncodable where
    EncodingContext: SomeDynamicSwiftCodableContext
{
    func encode(to encoder: Swift.Encoder, `as` type: TypeDefinition) throws
}

public typealias DynamicSwiftCodable = DynamicSwiftDecodable & DynamicSwiftEncodable

public extension DynamicSwiftDecodable where DecodingContext == DynamicCodableContext {
    @inlinable
    init(from decoder: Swift.Decoder, context: DecodingContext) throws {
        try self.init(from: decoder, as: context.type)
    }
    
    @inlinable
    init(from decoder: Swift.Decoder, as type: TypeDefinition, runtime: any Runtime) throws {
        try self.init(from: decoder, as: type)
    }
}

public extension Swift.Decodable {
    @inlinable
    init(from decoder: Swift.Decoder, `as` type: TypeDefinition) throws {
        try self.init(from: decoder)
    }
}

public extension Swift.Encodable {
    @inlinable
    func encode(to encoder: Swift.Encoder, as type: TypeDefinition) throws {
        try encode(to: encoder)
    }
}

public extension DynamicSwiftEncodable where EncodingContext == DynamicCodableContext {
    @inlinable
    func encode(to encoder: Swift.Encoder, context: EncodingContext) throws {
        try encode(to: encoder, as: context.type)
    }
    
    @inlinable
    func encode(to encoder: Swift.Encoder, as type: TypeDefinition, runtime: any Runtime) throws {
        try encode(to: encoder, as: type)
    }
}

public protocol CustomDynamicCoder {
    func check(type: TypeDefinition) -> Bool
    
    func decode<D: ScaleCodec.Decoder>(
        from decoder: inout D, as type: TypeDefinition,
        with coders: [ObjectIdentifier: any CustomDynamicCoder]?
    ) throws -> Value<TypeDefinition>
    
    func decode(
        from container: inout ValueDecodingContainer,
        as type: TypeDefinition,
        with coders: [ObjectIdentifier: any CustomDynamicCoder]?
    ) throws -> Value<TypeDefinition>
    
    func encode<C, E: ScaleCodec.Encoder>(
        value: Value<C>, in encoder: inout E, as type: TypeDefinition,
        with coders: [ObjectIdentifier: any CustomDynamicCoder]?
    ) throws
}

public extension CustomDynamicCoder {
    @inlinable
    func decode<D: ScaleCodec.Decoder>(
        from decoder: inout D, as type: TypeDefinition,
        with coders: [ObjectIdentifier: any CustomDynamicCoder]?
    ) throws -> Value<TypeDefinition> {
        try Value(from: &decoder, as: type, with: coders, skip: true)
    }
    
    func decode(
        from container: inout ValueDecodingContainer,
        as type: TypeDefinition,
        with coders: [ObjectIdentifier: any CustomDynamicCoder]?
    ) throws -> Value<TypeDefinition> {
        try Value(from: &container, as: type, with: coders, skip: true)
    }
    
    @inlinable
    func encode<C, E: ScaleCodec.Encoder>(
        value: Value<C>, in encoder: inout E, as type: TypeDefinition,
        with coders: [ObjectIdentifier: any CustomDynamicCoder]?
    ) throws {
        try value.encode(in: &encoder, as: type, with: coders, skip: true)
    }
}
