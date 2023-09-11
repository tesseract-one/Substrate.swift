//
//  Value+Encodable.swift
//  
//
//  Created by Yehor Popovych on 10.01.2023.
//

import Foundation
import ScaleCodec

extension Value {
    public enum EncodingError: Error {
        /// The composite type we're trying to encode is the wrong length for the type we're trying to encode it into.
        case mapIsWrongLength(
            /// The composite value that is the wrong length.
            actual: [String: Value<C>],
            /// The type we're trying to encode it into.
            expected: TypeDefinition,
            /// The length we're expecting our composite type to be to encode properly.
            expectedLen: Int
        )
        case sequenceIsWrongLength(
            /// The composite value that is the wrong length.
            actual: [Value<C>],
            /// The type we're trying to encode it into.
            expected: TypeDefinition,
            /// The length we're expecting our composite type to be to encode properly.
            expectedLen: Int
        )
        /// The variant we're trying to encode was not found in the type we're encoding into.
        case variantNotFound(
            /// The variant type we're trying to encode.
            actual: Variant,
            /// The type we're trying to encode it into.
            expected: TypeDefinition
        )
        /// The variant or composite field we're trying to encode is not present in the type we're encoding into.
        case mapFieldIsMissing(
            /// The name of the composite field we can't find.
            missingFieldName: String,
            /// The type we're trying to encode this into.
            expected: TypeDefinition
        )
        /// The [`Value`] type we're trying to encode is not the correct shape for the type we're trying to encode it into.
        case wrongShape(
            /// The value we're trying to encode.
            actual: Value<C>,
            /// The type we're trying to encode it into.
            expected: TypeDefinition
        )
        /// The type ID given is supposed to be compact encoded, but this is not possible to do automatically.
        case cannotCompactEncode(TypeDefinition)
    }
}

extension Value: DynamicEncodable {
    @inlinable
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E, as type: TypeDefinition) throws {
        try encode(in: &encoder, as: type, with: nil)
    }
    
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E,
                                              as type: TypeDefinition,
                                              with coders: [ObjectIdentifier: any CustomDynamicCoder]?,
                                              skip custom: Bool = false) throws
    {
        if !custom, let coder = coders?[type.objectId] {
            try coder.encode(value: self, in: &encoder, as: type, with: coders)
            return
        }
        switch type.definition {
        case .composite(fields: let fields):
            try _encodeComposite(type: type, fields: fields, coders: coders, in: &encoder)
        case .sequence(of: let seqTypeId):
            try _encodeSequence(type: type, valueType: seqTypeId, coders: coders, in: &encoder)
        case .array(count: let count, of: let arrTypeId):
            try _encodeArray(type: type, valueType: arrTypeId, count: count, coders: coders, in: &encoder)
        case .variant(variants: let variants):
            try _encodeVariant(type: type, variants: variants, coders: coders, in: &encoder)
        case .primitive(is: let primitive):
            try _encodePrimitive(type: type, prim: primitive, in: &encoder)
        case .compact(of: let vType):
            try _encodeCompact(type: type, of: vType, in: &encoder)
        case .bitsequence(format: let format):
            try _encodeBitSequence(type: type, format: format, in: &encoder)
        case .void: break
        }
    }
}

extension Value: RuntimeDynamicEncodable {
    @inlinable
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E,
                                              as type: TypeDefinition,
                                              runtime: any Runtime) throws
    {
        try self.encode(in: &encoder, as: type, with: runtime.dynamicCustomCoders)
    }
}

extension Value: RuntimeEncodable where C == TypeDefinition {
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: any Runtime) throws {
        try self.encode(in: &encoder, as: context, runtime: runtime)
    }
}

private extension Value {
    func _encodeComposite<E: ScaleCodec.Encoder>(
        type: TypeDefinition, fields: [TypeDefinition.Field],
        coders: [ObjectIdentifier: any CustomDynamicCoder]?, in encoder: inout E
    ) throws {
        switch value {
        case .map(let mFields):
            if fields.count == 1 && mFields.count != 1 {
                // The composite we've provided doesn't have 1 field; it has many.
                // perhaps the type we're encoding to is a wrapper type then; let's
                // jump in and try to encode our composite to the contents of it (1
                // field composites are transparent anyway in SCALE terms).
                try encode(in: &encoder, as: fields[0].type.strong, with: coders)
            } else {
                try _encodeCompositeFields(type: type, fields: fields, coders: coders, in: &encoder)
            }
        case .sequence(let values):
            if fields.count == 1 && values.count != 1 {
                // The composite we've provided doesn't have 1 field; it has many.
                // perhaps the type we're encoding to is a wrapper type then; let's
                // jump in and try to encode our composite to the contents of it (1
                // field composites are transparent anyway in SCALE terms).
                try encode(in: &encoder, as: fields[0].type.strong, with: coders)
            } else {
                try _encodeCompositeFields(type: type, fields: fields, coders: coders, in: &encoder)
            }
        default:
            if fields.count == 1 {
                // We didn't provide a composite type, but the composite type we're
                // aiming for has exactly 1 field. Perhaps it's a wrapper type, so let's
                // aim to encode to the contents of it instead (1 field composites are
                // transparent anyway in SCALE terms).
                try encode(in: &encoder, as: fields[0].type.strong, with: coders)
            } else {
                throw EncodingError.wrongShape(actual: self, expected: type.strong)
            }
        }
    }
    
    func _encodeSequence<E: ScaleCodec.Encoder>(
        type: TypeDefinition, valueType: TypeDefinition.Weak,
        coders: [ObjectIdentifier: any CustomDynamicCoder]?, in encoder: inout E
    ) throws {
        switch value {
        case .sequence(let values):
            try values.encode(in: &encoder) { value, encoder in
                try value.encode(in: &encoder, as: valueType.strong, with: coders)
            }
        case .primitive(let primitive):
            switch primitive {
            case .bytes(let bytes):
                guard case .primitive(is: .u8) = valueType.definition else {
                    throw EncodingError.wrongShape(actual: self, expected: type.strong)
                }
                try encoder.encode(bytes)
            default:
                throw EncodingError.wrongShape(actual: self, expected: type.strong)
            }
        default:
            throw EncodingError.wrongShape(actual: self, expected: type.strong)
        }
    }
    
    func _encodeArray<E: ScaleCodec.Encoder>(
        type: TypeDefinition, valueType: TypeDefinition.Weak, count: UInt32,
        coders: [ObjectIdentifier: any CustomDynamicCoder]?, in encoder: inout E
    ) throws {
        switch value {
        case .sequence(let values):
            guard values.count == count else {
                throw EncodingError.sequenceIsWrongLength(
                    actual: values, expected: type.strong, expectedLen: Int(count)
                )
            }
            for value in values {
                try value.encode(in: &encoder, as: valueType.strong, with: coders)
            }
        case .primitive(let primitive):
            switch primitive {
            case .bytes(let bytes):
                guard bytes.count == count else {
                    throw EncodingError.wrongShape(actual: self, expected: type.strong)
                }
                guard case .primitive(is: .u8) = valueType.definition else {
                    throw EncodingError.wrongShape(actual: self, expected: type.strong)
                }
                try encoder.encode(bytes, .fixed(UInt(count)))
            default:
                throw EncodingError.wrongShape(actual: self, expected: type.strong)
            }
        default:
            throw EncodingError.wrongShape(actual: self, expected: type.strong)
        }
    }
    
    func _encodeVariant<E: ScaleCodec.Encoder>(
        type: TypeDefinition, variants: [TypeDefinition.Variant],
        coders: [ObjectIdentifier: any CustomDynamicCoder]?, in encoder: inout E
    ) throws {
        guard case .variant(let variant) = value else {
            throw EncodingError.wrongShape(actual: self, expected: type.strong)
        }
        guard let varType = variants.first(where: { $0.name == variant.name }) else {
            throw EncodingError.variantNotFound(actual: variant, expected: type.strong)
        }
        try encoder.encode(varType.index, .enumCaseId)
        switch variant {
        case .map(name: _, fields: let map):
            try Value(value: .map(map), context: context)._encodeCompositeFields(
                type: type, fields: varType.fields, coders: coders, in: &encoder
            )
        case .sequence(name: _, values: let seq):
            try Value(value: .sequence(seq), context: context)._encodeCompositeFields(
                type: type, fields: varType.fields, coders: coders, in: &encoder
            )
        }
    }
    
    func _encodeCompositeFields<E: ScaleCodec.Encoder>(
        type: TypeDefinition, fields: [TypeDefinition.Field],
        coders: [ObjectIdentifier: any CustomDynamicCoder]?, in encoder: inout E
    ) throws {
        if let map = self.map {
            guard map.count == fields.count else {
                throw EncodingError.mapIsWrongLength(
                    actual: map, expected: type.strong, expectedLen: fields.count
                )
            }
            guard map.count > 0 else { return }
            guard fields[0].name != nil else {
                throw EncodingError.wrongShape(actual: self, expected: type.strong)
            }
            for field in fields {
                let name = field.name! // should be ok. Fields is named
                guard let value = map[name] else {
                    throw EncodingError.mapFieldIsMissing(missingFieldName: name, expected: field.type.strong)
                }
                try value.encode(in: &encoder, as: field.type.strong, with: coders)
            }
        } else {
            let values = self.sequence!
            guard values.count == fields.count else {
                throw EncodingError.sequenceIsWrongLength(
                    actual: values, expected: type.strong, expectedLen: fields.count
                )
            }
            guard values.count > 0 else { return }
            for (field, value) in zip(fields, values) {
                try value.encode(in: &encoder, as: field.type.strong, with: coders)
            }
        }
    }
    
    func _encodePrimitive<E: ScaleCodec.Encoder>(
        type: TypeDefinition, prim: NetworkType.Primitive, in encoder: inout E
    ) throws {
        guard case .primitive(let primitive) = value else {
            throw EncodingError.wrongShape(actual: self, expected: type.strong)
        }
        switch (prim, primitive) {
        case (.bool, .bool(let bool)): try encoder.encode(bool)
        case (.char, .char(let char)): try encoder.encode(char)
        case (.str, .string(let str)): try encoder.encode(str)
        case (.u8, let primitive):
            try encoder.encode(_pritimiveToInt(primitive: primitive, type: type, UInt8.self))
        case (.u16, let primitive):
            try encoder.encode(_pritimiveToInt(primitive: primitive, type: type, UInt16.self))
        case (.u32, let primitive):
            try encoder.encode(_pritimiveToInt(primitive: primitive, type: type, UInt32.self))
        case (.u64, let primitive):
            try encoder.encode(_pritimiveToInt(primitive: primitive, type: type, UInt64.self))
        case (.u128, let primitive):
            try encoder.encode(_pritimiveToInt(primitive: primitive, type: type, UInt128.self))
        case (.u256, let primitive):
            try encoder.encode(_pritimiveToInt(primitive: primitive, type: type, UInt256.self))
        case (.i8, let primitive):
            try encoder.encode(_pritimiveToInt(primitive: primitive, type: type, Int8.self))
        case (.i16, let primitive):
            try encoder.encode(_pritimiveToInt(primitive: primitive, type: type, Int16.self))
        case (.i32, let primitive):
            try encoder.encode(_pritimiveToInt(primitive: primitive, type: type, Int32.self))
        case (.i64, let primitive):
            try encoder.encode(_pritimiveToInt(primitive: primitive, type: type, Int64.self))
        case (.i128, let primitive):
            try encoder.encode(_pritimiveToInt(primitive: primitive, type: type, Int128.self))
        case (.i256, let primitive):
            try encoder.encode(_pritimiveToInt(primitive: primitive, type: type, Int256.self))
        default:
            throw EncodingError.wrongShape(actual: self, expected: type.strong)
        }
    }
    
    func _pritimiveToInt<INT: FixedWidthInteger>(
        primitive: Primitive, type: TypeDefinition, _: INT.Type
    ) throws -> INT {
        switch primitive {
        case .int(let int):
            guard let val = INT(exactly: int) else {
                throw EncodingError.wrongShape(actual: self, expected: type.strong)
            }
            return val
        case .uint(let int):
            guard let val = INT(exactly: int) else {
                throw EncodingError.wrongShape(actual: self, expected: type.strong)
            }
            return val
        default:
            throw EncodingError.wrongShape(actual: self, expected: type.strong)
        }
    }
    
    func _encodeCompact<E: ScaleCodec.Encoder>(
        type: TypeDefinition, of: TypeDefinition.Weak, in encoder: inout E
    ) throws {
        // Resolve to a primitive type inside the compact encoded type (or fail if
        // we hit some type we wouldn't know how to work with).
        var innerType = of
        var innerCtType: CompactTy? = nil
        while innerCtType == nil {
            switch innerType.definition {
            case .composite(fields: let fields):
                guard fields.count == 1 else {
                    throw EncodingError.cannotCompactEncode(innerType.strong)
                }
                innerType = fields[0].type
            case .primitive(is: let prim):
                switch prim {
                case .u8: innerCtType = .u8
                case .u16: innerCtType = .u16
                case .u32: innerCtType = .u32
                case .u64: innerCtType = .u64
                case .u128: innerCtType = .u128
                case .u256: innerCtType = .u256
                default: throw EncodingError.cannotCompactEncode(innerType.strong)
                }
            default: throw EncodingError.cannotCompactEncode(innerType.strong)
            }
        }
        // resolve to the innermost value that we have in the same way, expecting to get out
        // a single primitive value.
        var value = self
        var innerPrimitive: Primitive? = nil
        while innerPrimitive == nil {
            switch value.value {
            case .map(let map):
                guard map.count == 1 else {
                    throw EncodingError.wrongShape(actual: value, expected: innerType.strong)
                }
                value = map.values.first!
            case .sequence(let seq):
                guard seq.count == 1 else {
                    throw EncodingError.wrongShape(actual: value, expected: innerType.strong)
                }
                value = seq.first!
            case .primitive(let primitive):
                innerPrimitive = primitive
            default:
                throw EncodingError.wrongShape(actual: value, expected: innerType.strong)
            }
        }
        // Try to compact encode the primitive type we have into the type asked for:
        switch innerCtType! {
        case .u8:
            try encoder.encode(
                value._pritimiveToInt(primitive: innerPrimitive!, type: type, UInt8.self),
                .compact
            )
        case .u16:
            try encoder.encode(
                value._pritimiveToInt(primitive: innerPrimitive!, type: type, UInt16.self),
                .compact
            )
        case .u32:
            try encoder.encode(
                value._pritimiveToInt(primitive: innerPrimitive!, type: type, UInt32.self),
                .compact
            )
        case .u64:
            try encoder.encode(
                value._pritimiveToInt(primitive: innerPrimitive!, type: type, UInt64.self),
                .compact
            )
        case .u128:
            try encoder.encode(
                value._pritimiveToInt(primitive: innerPrimitive!, type: type, UInt128.self),
                .compact
            )
        case .u256:
            try encoder.encode(
                value._pritimiveToInt(primitive: innerPrimitive!, type: type, UInt256.self),
                .compact
            )
        }
    }
    
    func _encodeBitSequence<E: ScaleCodec.Encoder>(
        type: TypeDefinition, format: BitSequence.Format, in encoder: inout E
    ) throws {
        switch value {
        case .bitSequence(let seq):
            try encoder.encode(seq, .format(format))
        case .sequence(let values):
            let seq = try values.map {
                guard case .primitive(.bool(let bool)) = $0.value else {
                    throw EncodingError.wrongShape(actual: self, expected: type.strong)
                }
                return bool
            }
            try encoder.encode(BitSequence(seq), .format(format))
        default: throw EncodingError.wrongShape(actual: self, expected: type.strong)
        }
    }
}

private enum CompactTy {
    case u8
    case u16
    case u32
    case u64
    case u128
    case u256
}
