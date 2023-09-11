//
//  DynamicCodable.swift
//  
//
//  Created by Yehor Popovych on 11/09/2023.
//

import Foundation
import ScaleCodec

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

public protocol CustomDynamicCoder {
    func checkType(type: TypeDefinition) -> Bool
    
    func decode<D: ScaleCodec.Decoder>(
        from decoder: inout D, as type: TypeDefinition,
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
    
    @inlinable
    func encode<C, E: ScaleCodec.Encoder>(
        value: Value<C>, in encoder: inout E, as type: TypeDefinition,
        with coders: [ObjectIdentifier: any CustomDynamicCoder]?
    ) throws {
        try value.encode(in: &encoder, as: type, with: coders, skip: true)
    }
}
