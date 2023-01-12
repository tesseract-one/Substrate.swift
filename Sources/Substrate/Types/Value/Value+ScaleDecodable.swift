//
//  Registry+ScaleDecodable.swift
//  
//
//  Created by Yehor Popovych on 10.01.2023.
//

import Foundation
import ScaleCodec

extension Value {
    public enum DecodingError: Error {
        case variantNotFound(UInt8, RuntimeTypeId)
        /// The type we're trying to encode into cannot be found in the type registry provided.
        case typeNotFound(RuntimeTypeId)
        /// There was an error trying to encode the bit sequence provided.
        case bitSequenceError(Error)
        /// The type ID given is supposed to be compact encoded, but this is not possible to do automatically.
        case cannotCompactDecode(RuntimeTypeId)
    }
}

extension Value: RegistryScaleDynamicDecodable where C == RuntimeTypeId {
    public init(from decoder: ScaleDecoder, `as` type: RuntimeTypeId, registry: Registry) throws {
        guard let typeInfo = registry.types[type] else {
            throw DecodingError.typeNotFound(type)
        }
        switch typeInfo.typeDefinition {
        case .composite(fields: let fields):
            self = try Self._decodeComposite(from: decoder, type: type, fields: fields, registry: registry)
        case .sequence(of: let vType):
            self = try Self._decodeSequence(from: decoder, type: type, valueType: vType, registry: registry)
        case .variant(variants: let vars):
            self = try Self._decodeVariant(from: decoder, type: type, variants: vars, registry: registry)
        case .array(count: let count, of: let vType):
            self = try Self._decodeArray(
                from: decoder, type: type, valueType: vType, count: count, registry: registry
            )
        case .tuple(components: let fields):
            self = try Self._decodeTuple(from: decoder, type: type, fields: fields, registry: registry)
        case .primitive(is: let pType):
            self = try Self._decodePrimitive(from: decoder, type: type, prim: pType, registry: registry)
        case .compact(of: let cType):
            self = try Self._decodeCompact(from: decoder, type: type, of: cType, registry: registry)
        case .bitsequence(store: let store, order: let order):
            self = try Self._decodeBitSequence(
                from: decoder, type: type, store: store, order: order, registry: registry
            )
        }
    }
}

extension Registry {
    public func decode(from decoder: ScaleDecoder, type: RuntimeTypeId) throws -> Value<RuntimeTypeId> {
        try Value(from: decoder, as: type, registry: self)
    }
}

private extension Value where C == RuntimeTypeId {
    static func _decodeComposite(
        from decoder: ScaleDecoder, type: RuntimeTypeId, fields: [RuntimeTypeField], registry: Registry
    ) throws -> Self {
        guard fields.count > 0 else {
            return Value(value: .sequence([]), context: type)
        }
        if fields[0].name != nil { // Map
            var map: [String: Value<C>] = Dictionary(minimumCapacity: fields.count)
            for field in fields {
                map[field.name!] = try Value(from: decoder, as: field.type, registry: registry)
            }
            return Value(value: .map(map), context: type)
        } else {
            let seq = try fields.map {
                try Value(from: decoder, as: $0.type, registry: registry)
            }
            return Value(value: .sequence(seq), context: type)
        }
    }
    
    static func _decodeSequence(
        from decoder: ScaleDecoder, type: RuntimeTypeId, valueType: RuntimeTypeId, registry: Registry
    ) throws -> Self {
        guard let vTypeInfo = registry.types[valueType] else {
            throw DecodingError.typeNotFound(valueType)
        }
        if case .primitive(is: .u8) = vTypeInfo.typeDefinition {
            return try Value(value: .primitive(.bytes(decoder.decode())), context: type)
        } else {
            let values = try Array(from: decoder) { decoder in
                try Value(from: decoder, as: valueType, registry: registry)
            }
            return Value(value: .sequence(values), context: type)
        }
    }
    
    static func _decodeVariant(
        from decoder: ScaleDecoder, type: RuntimeTypeId, variants: [RuntimeTypeVariantItem], registry: Registry
    ) throws -> Self {
        let index = try decoder.decode(.enumCaseId)
        guard let variant = variants.first(where: { $0.index == index }) else {
            throw DecodingError.variantNotFound(index, type)
        }
        let composite = try _decodeComposite(from: decoder, type: type, fields: variant.fields, registry: registry)
        if let map = composite.map {
            return Value(value: .variant(.map(name: variant.name, fields: map)), context: type)
        }
        return Value(value: .variant(.sequence(name: variant.name, values: composite.sequence!)), context: type)
    }
    
    static func _decodeArray(
        from decoder: ScaleDecoder, type: RuntimeTypeId,
        valueType: RuntimeTypeId, count: UInt32, registry: Registry
    ) throws -> Self {
        guard let vTypeInfo = registry.types[valueType] else {
            throw DecodingError.typeNotFound(valueType)
        }
        if case .primitive(is: .u8) = vTypeInfo.typeDefinition {
            return try Value(value: .primitive(.bytes(decoder.decode(.fixed(UInt(count))))), context: type)
        } else {
            var values: [Value<C>] = []
            values.reserveCapacity(Int(count))
            for _ in 0..<count {
                try values.append(Value(from: decoder, as: valueType, registry: registry))
            }
            return Value(value: .sequence(values), context: type)
        }
    }
    
    static func _decodeTuple(
        from decoder: ScaleDecoder, type: RuntimeTypeId, fields: [RuntimeTypeId], registry: Registry
    ) throws -> Self {
        let seq = try fields.map { try Value(from: decoder, as: $0, registry: registry) }
        return Value(value: .sequence(seq), context: type)
    }
    
    static func _decodePrimitive(
        from decoder: ScaleDecoder, type: RuntimeTypeId, prim: RuntimeTypePrimitive, registry: Registry
    ) throws -> Self {
        switch prim {
        case .bool: return Value(value: .primitive(.bool(try decoder.decode())), context: type)
        case .char: return Value(value: .primitive(.char(try decoder.decode())), context: type)
        case .str: return Value(value: .primitive(.string(try decoder.decode())), context: type)
        case .u8:
            return Value(value: .primitive(.u256(UInt256(try decoder.decode(UInt8.self)))),
                         context: type)
        case .u16:
            return Value(value: .primitive(.u256(UInt256(try decoder.decode(UInt16.self)))),
                         context: type)
        case .u32:
            return Value(value: .primitive(.u256(UInt256(try decoder.decode(UInt32.self)))),
                         context: type)
        case .u64:
            return Value(value: .primitive(.u256(UInt256(try decoder.decode(UInt64.self)))),
                         context: type)
        case .u128:
            return Value(value: .primitive(.u256(UInt256(try decoder.decode(UInt128.self)))),
                         context: type)
        case .u256:
            return Value(value: .primitive(.u256(try decoder.decode())), context: type)
        case .i8:
            return Value(value: .primitive(.i256(Int256(try decoder.decode(Int8.self)))),
                         context: type)
        case .i16:
            return Value(value: .primitive(.i256(Int256(try decoder.decode(Int16.self)))),
                         context: type)
        case .i32:
            return Value(value: .primitive(.i256(Int256(try decoder.decode(Int32.self)))),
                         context: type)
        case .i64:
            return Value(value: .primitive(.i256(Int256(try decoder.decode(Int64.self)))),
                         context: type)
        case .i128:
            return Value(value: .primitive(.i256(Int256(try decoder.decode(Int128.self)))),
                         context: type)
        case .i256:
            return Value(value: .primitive(.i256(try decoder.decode())), context: type)
        }
    }
    
    static func _decodeCompact(
        from decoder: ScaleDecoder, type: RuntimeTypeId, of: RuntimeTypeId, registry: Registry
    ) throws -> Self {
        var innerTypeId = of
        var value: Value<C>? = nil
        while value == nil {
            guard let innerType = registry.types[innerTypeId]?.typeDefinition else {
                throw DecodingError.typeNotFound(type)
            }
            switch innerType {
            case .primitive(is: let prim):
                switch prim {
                case .u8:
                    value = try Value(
                        value: .primitive(.u256(UInt256(decoder.decode(UInt8.self, .compact)))),
                        context: type)
                case .u16:
                    value = try Value(
                        value: .primitive(.u256(UInt256(decoder.decode(UInt16.self, .compact)))),
                        context: type)
                case .u32:
                    value = try Value(
                        value: .primitive(.u256(UInt256(decoder.decode(UInt32.self, .compact)))),
                        context: type)
                case .u64:
                    value = try Value(
                        value: .primitive(.u256(UInt256(decoder.decode(UInt64.self, .compact)))),
                        context: type)
                case .u128:
                    value = try Value(
                        value: .primitive(.u256(UInt256(decoder.decode(UInt128.self, .compact)))),
                        context: type)
                case .u256:
                    value = try Value(value: .primitive(.u256(decoder.decode(.compact))),
                                      context: type)
                default: throw DecodingError.cannotCompactDecode(innerTypeId)
                }
            case .composite(fields: let fields):
                guard fields.count == 1 else {
                    throw DecodingError.cannotCompactDecode(innerTypeId)
                }
                innerTypeId = fields[0].type
            case .tuple(components: let fields):
                guard fields.count == 1 else {
                    throw DecodingError.cannotCompactDecode(innerTypeId)
                }
                innerTypeId = fields[0]
            default: throw DecodingError.cannotCompactDecode(innerTypeId)
            }
        }
        return value!
    }
    
    static func _decodeBitSequence(
        from decoder: ScaleDecoder, type: RuntimeTypeId, store: RuntimeTypeId, order: RuntimeTypeId, registry: Registry
    ) throws -> Self {
        let format = try BitSequence.Format(store: store, order: order, registry: registry)
        return try Value(value: .bitSequence(decoder.decode(.format(format))), context: type)
    }
}