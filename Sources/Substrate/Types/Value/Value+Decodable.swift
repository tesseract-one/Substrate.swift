//
//  Value+Decodable.swift
//  
//
//  Created by Yehor Popovych on 10.01.2023.
//

import Foundation
import ScaleCodec

extension Value {
    public enum DecodingError: Error {
        case variantNotFound(UInt8, TypeDefinition)
        /// The type given is supposed to be compact encoded, but this is not possible to do automatically.
        case cannotCompactDecode(TypeDefinition)
    }
}

extension Value: DynamicDecodable where C == TypeDefinition {
    @inlinable
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, as type: TypeDefinition) throws {
        try self.init(from: &decoder, as: type, with: nil)
    }
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                       as type: TypeDefinition,
                                       with coders: [ObjectIdentifier: any CustomDynamicCoder]?,
                                       skip custom: Bool = false) throws
    {
        if !custom, let coder = coders?[type.objectId] {
            self = try coder.decode(from: &decoder, as: type, with: coders)
            return
        }
        switch type.definition {
        case .composite(fields: let fields):
            self = try Self._decodeComposite(from: &decoder, type: type, fields: fields, coders: coders)
        case .sequence(of: let vType):
            self = try Self._decodeSequence(from: &decoder, type: type, valueType: vType, coders: coders)
        case .variant(variants: let vars):
            self = try Self._decodeVariant(from: &decoder, type: type, variants: vars, coders: coders)
        case .array(count: let count, of: let vType):
            self = try Self._decodeArray(
                from: &decoder, type: type, valueType: vType, count: count, coders: coders
            )
        case .primitive(is: let pType):
            self = try Self._decodePrimitive(from: &decoder, type: type, prim: pType)
        case .compact(of: let cType):
            self = try Self._decodeCompact(from: &decoder, type: type, of: cType)
        case .bitsequence(format: let format):
            self.value = try .bitSequence(decoder.decode(.format(format)))
            self.context = type
        case .void:
            self.value = .sequence([])
            self.context = type
        }
    }
}

extension Value: RuntimeDynamicDecodable where C == TypeDefinition {
    @inlinable
    public init<D: ScaleCodec.Decoder>(from decoder: inout D,
                                       as type: TypeDefinition,
                                       runtime: Runtime) throws
    {
        try self.init(from: &decoder, as: type, with: runtime.dynamicCustomCoders)
    }
}

private extension Value where C == TypeDefinition {
    static func _decodeComposite<D: ScaleCodec.Decoder>(
        from decoder: inout D, type: TypeDefinition, fields: [TypeDefinition.Field],
        coders: [ObjectIdentifier: any CustomDynamicCoder]?
    ) throws -> Self {
        guard fields.count > 0 else {
            return Value(value: .sequence([]), context: type)
        }
        if fields[0].name != nil { // Map
            var map: [String: Value<C>] = Dictionary(minimumCapacity: fields.count)
            for field in fields {
                map[field.name!] = try Value(from: &decoder, as: *field.type, with: coders)
            }
            return Value(value: .map(map), context: type)
        } else {
            let seq = try fields.map {
                try Value(from: &decoder, as: *$0.type, with: coders)
            }
            return Value(value: .sequence(seq), context: type)
        }
    }
    
    static func _decodeSequence<D: ScaleCodec.Decoder>(
        from decoder: inout D, type: TypeDefinition, valueType: TypeDefinition.Weak,
        coders: [ObjectIdentifier: any CustomDynamicCoder]?
    ) throws -> Self {
        if case .primitive(is: .u8) = valueType.definition {
            return try Value(value: .primitive(.bytes(decoder.decode())), context: type)
        } else {
            let values = try Array(from: &decoder) { decoder in
                try Value(from: &decoder, as: *valueType, with: coders)
            }
            return Value(value: .sequence(values), context: type)
        }
    }
    
    static func _decodeVariant<D: ScaleCodec.Decoder>(
        from decoder: inout D, type: TypeDefinition, variants: [TypeDefinition.Variant],
        coders: [ObjectIdentifier: any CustomDynamicCoder]?
    ) throws -> Self {
        let index = try decoder.decode(.enumCaseId)
        guard let variant = variants.first(where: { $0.index == index }) else {
            throw DecodingError.variantNotFound(index, type.strong)
        }
        let composite = try _decodeComposite(from: &decoder, type: type,
                                             fields: variant.fields, coders: coders)
        if let map = composite.map {
            return Value(value: .variant(.map(name: variant.name, fields: map)), context: type)
        }
        return Value(value: .variant(.sequence(name: variant.name, values: composite.sequence!)), context: type)
    }
    
    static func _decodeArray<D: ScaleCodec.Decoder>(
        from decoder: inout D, type: TypeDefinition,
        valueType: TypeDefinition.Weak, count: UInt32,
        coders: [ObjectIdentifier: any CustomDynamicCoder]?
    ) throws -> Self {
        if case .primitive(is: .u8) = valueType.definition {
            return try Value(value: .primitive(.bytes(decoder.decode(.fixed(UInt(count))))),
                             context: type)
        } else {
            var values: [Value<C>] = []
            values.reserveCapacity(Int(count))
            for _ in 0..<count {
                try values.append(Value(from: &decoder, as: *valueType, with: coders))
            }
            return Value(value: .sequence(values), context: type)
        }
    }
    
    static func _decodePrimitive<D: ScaleCodec.Decoder>(
        from decoder: inout D, type: TypeDefinition, prim: NetworkType.Primitive
    ) throws -> Self {
        switch prim {
        case .bool: return Value(value: .primitive(.bool(try decoder.decode())), context: type)
        case .char: return Value(value: .primitive(.char(try decoder.decode())), context: type)
        case .str: return Value(value: .primitive(.string(try decoder.decode())), context: type)
        case .u8:
            return Value(value: .primitive(.uint(UInt256(try decoder.decode(UInt8.self)))),
                         context: type)
        case .u16:
            return Value(value: .primitive(.uint(UInt256(try decoder.decode(UInt16.self)))),
                         context: type)
        case .u32:
            return Value(value: .primitive(.uint(UInt256(try decoder.decode(UInt32.self)))),
                         context: type)
        case .u64:
            return Value(value: .primitive(.uint(UInt256(try decoder.decode(UInt64.self)))),
                         context: type)
        case .u128:
            return Value(value: .primitive(.uint(UInt256(try decoder.decode(UInt128.self)))),
                         context: type)
        case .u256:
            return Value(value: .primitive(.uint(try decoder.decode())), context: type)
        case .i8:
            return Value(value: .primitive(.int(Int256(try decoder.decode(Int8.self)))),
                         context: type)
        case .i16:
            return Value(value: .primitive(.int(Int256(try decoder.decode(Int16.self)))),
                         context: type)
        case .i32:
            return Value(value: .primitive(.int(Int256(try decoder.decode(Int32.self)))),
                         context: type)
        case .i64:
            return Value(value: .primitive(.int(Int256(try decoder.decode(Int64.self)))),
                         context: type)
        case .i128:
            return Value(value: .primitive(.int(Int256(try decoder.decode(Int128.self)))),
                         context: type)
        case .i256:
            return Value(value: .primitive(.int(try decoder.decode())), context: type)
        }
    }
    
    static func _decodeCompact<D: ScaleCodec.Decoder>(
        from decoder: inout D, type: TypeDefinition, of: TypeDefinition.Weak
    ) throws -> Self {
        var innerType = of
        var value: Value<C>? = nil
        while value == nil {
            switch innerType.definition {
            case .primitive(is: let prim):
                switch prim {
                case .u8:
                    value = try Value(
                        value: .primitive(.uint(UInt256(decoder.decode(UInt8.self, .compact)))),
                        context: type)
                case .u16:
                    value = try Value(
                        value: .primitive(.uint(UInt256(decoder.decode(UInt16.self, .compact)))),
                        context: type)
                case .u32:
                    value = try Value(
                        value: .primitive(.uint(UInt256(decoder.decode(UInt32.self, .compact)))),
                        context: type)
                case .u64:
                    value = try Value(
                        value: .primitive(.uint(UInt256(decoder.decode(UInt64.self, .compact)))),
                        context: type)
                case .u128:
                    value = try Value(
                        value: .primitive(.uint(UInt256(decoder.decode(UInt128.self, .compact)))),
                        context: type)
                case .u256:
                    value = try Value(value: .primitive(.uint(decoder.decode(.compact))),
                                      context: type)
                default: throw DecodingError.cannotCompactDecode(innerType.strong)
                }
            case .composite(fields: let fields):
                guard fields.count == 1 else {
                    throw DecodingError.cannotCompactDecode(innerType.strong)
                }
                innerType = fields[0].type
            default: throw DecodingError.cannotCompactDecode(innerType.strong)
            }
        }
        return value!
    }
}
