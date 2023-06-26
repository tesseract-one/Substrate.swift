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
            expected: RuntimeTypeId,
            /// The length we're expecting our composite type to be to encode properly.
            expectedLen: Int
        )
        case sequenceIsWrongLength(
            /// The composite value that is the wrong length.
            actual: [Value<C>],
            /// The type we're trying to encode it into.
            expected: RuntimeTypeId,
            /// The length we're expecting our composite type to be to encode properly.
            expectedLen: Int
        )
        /// The variant we're trying to encode was not found in the type we're encoding into.
        case variantNotFound(
            /// The variant type we're trying to encode.
            actual: Variant,
            /// The type we're trying to encode it into.
            expected: RuntimeTypeId
        )
        /// The variant or composite field we're trying to encode is not present in the type we're encoding into.
        case mapFieldIsMissing(
            /// The name of the composite field we can't find.
            missingFieldName: String,
            /// The type we're trying to encode this into.
            expected: RuntimeTypeId
        )
        /// The type we're trying to encode into cannot be found in the type registry provided.
        case typeNotFound(RuntimeTypeId)
        /// The [`Value`] type we're trying to encode is not the correct shape for the type we're trying to encode it into.
        case wrongShape(
            /// The value we're trying to encode.
            actual: Value<C>,
            /// The type we're trying to encode it into.
            expected: RuntimeTypeId
        )
        /// The type ID given is supposed to be compact encoded, but this is not possible to do automatically.
        case cannotCompactEncode(RuntimeTypeId)
    }
}

extension Value: RuntimeDynamicEncodable {
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E, as type: RuntimeTypeId, runtime: Runtime) throws {
        guard let typeInfo = runtime.resolve(type: type) else {
            throw EncodingError.typeNotFound(type)
        }
        switch typeInfo.definition {
        case .composite(fields: let fields):
            try _encodeComposite(id: type, fields: fields, runtime: runtime, in: &encoder)
        case .sequence(of: let seqTypeId):
            try _encodeSequence(id: type, valueType: seqTypeId, runtime: runtime, in: &encoder)
        case .array(count: let count, of: let arrTypeId):
            try _encodeArray(id: type, valueType: arrTypeId, count: count, runtime: runtime, in: &encoder)
        case .tuple(components: let fields):
            try _encodeTuple(id: type, fields: fields, runtime: runtime, in: &encoder)
        case .variant(variants: let variants):
            try _encodeVariant(id: type, variants: variants, runtime: runtime, in: &encoder)
        case .primitive(is: let primitive):
            try _encodePrimitive(id: type, type: primitive, in: &encoder)
        case .compact(of: let type):
            try _encodeCompact(id: type, type: type, runtime: runtime, in: &encoder)
        case .bitsequence(store: let store, order: let order):
            try _encodeBitSequence(id: type, store: store, order: order, runtime: runtime, in: &encoder)
        }
    }
}

extension Runtime {
    public func encode<C, E: ScaleCodec.Encoder>(value: Value<C>, `as` type: RuntimeTypeId, in encoder: inout E) throws {
        try value.encode(in: &encoder, as: type, runtime: self)
    }
}

private extension Value {
    func _encodeComposite<E: ScaleCodec.Encoder>(
        id: RuntimeTypeId, fields: [RuntimeTypeField], runtime: Runtime, in encoder: inout E
    ) throws {
        switch value {
        case .map(let mFields):
            if fields.count == 1 && mFields.count != 1 {
                // The composite we've provided doesn't have 1 field; it has many.
                // perhaps the type we're encoding to is a wrapper type then; let's
                // jump in and try to encode our composite to the contents of it (1
                // field composites are transparent anyway in SCALE terms).
                try encode(in: &encoder, as: fields[0].type, runtime: runtime)
            } else {
                try _encodeCompositeFields(id: id, fields: fields, runtime: runtime, in: &encoder)
            }
        case .sequence(let values):
            if fields.count == 1 && values.count != 1 {
                // The composite we've provided doesn't have 1 field; it has many.
                // perhaps the type we're encoding to is a wrapper type then; let's
                // jump in and try to encode our composite to the contents of it (1
                // field composites are transparent anyway in SCALE terms).
                try encode(in: &encoder, as: fields[0].type, runtime: runtime)
            } else {
                try _encodeCompositeFields(id: id, fields: fields, runtime: runtime, in: &encoder)
            }
        default:
            if fields.count == 1 {
                // We didn't provide a composite type, but the composite type we're
                // aiming for has exactly 1 field. Perhaps it's a wrapper type, so let's
                // aim to encode to the contents of it instead (1 field composites are
                // transparent anyway in SCALE terms).
                try encode(in: &encoder, as: fields[0].type, runtime: runtime)
            } else {
                throw EncodingError.wrongShape(actual: self, expected: id)
            }
        }
    }
    
    func _encodeSequence<E: ScaleCodec.Encoder>(
        id: RuntimeTypeId, valueType: RuntimeTypeId, runtime: Runtime, in encoder: inout E
    ) throws {
        switch value {
        case .sequence(let values):
            try values.encode(in: &encoder) { value, encoder in
                try value.encode(in: &encoder, as: valueType, runtime: runtime)
            }
        case .primitive(let primitive):
            switch primitive {
            case .bytes(let bytes):
                guard let vTypeInfo = runtime.resolve(type: valueType) else {
                    throw EncodingError.typeNotFound(valueType)
                }
                guard case .primitive(is: .u8) = vTypeInfo.definition else {
                    throw EncodingError.wrongShape(actual: self, expected: id)
                }
                try encoder.encode(bytes)
            default:
                throw EncodingError.wrongShape(actual: self, expected: id)
            }
        default:
            throw EncodingError.wrongShape(actual: self, expected: id)
        }
    }
    
    func _encodeArray<E: ScaleCodec.Encoder>(
        id: RuntimeTypeId, valueType: RuntimeTypeId, count: UInt32,
        runtime: Runtime, in encoder: inout E
    ) throws {
        switch value {
        case .sequence(let values):
            guard values.count == count else {
                throw EncodingError.sequenceIsWrongLength(
                    actual: values, expected: id, expectedLen: Int(count)
                )
            }
            for value in values {
                try value.encode(in: &encoder, as: valueType, runtime: runtime)
            }
        case .primitive(let primitive):
            switch primitive {
            case .bytes(let bytes):
                guard bytes.count == count else {
                    throw EncodingError.wrongShape(actual: self, expected: id)
                }
                guard let vTypeInfo = runtime.resolve(type: valueType) else {
                    throw EncodingError.typeNotFound(valueType)
                }
                guard case .primitive(is: .u8) = vTypeInfo.definition else {
                    throw EncodingError.wrongShape(actual: self, expected: id)
                }
                try encoder.encode(bytes, .fixed(UInt(count)))
            default:
                throw EncodingError.wrongShape(actual: self, expected: id)
            }
        default:
            throw EncodingError.wrongShape(actual: self, expected: id)
        }
    }
    
    func _encodeTuple<E: ScaleCodec.Encoder>(
        id: RuntimeTypeId, fields: [RuntimeTypeId], runtime: Runtime, in encoder: inout E
    ) throws {
        switch value {
        case .sequence(let values):
            guard values.count == fields.count else {
                throw EncodingError.sequenceIsWrongLength(
                    actual: values, expected: id, expectedLen: fields.count
                )
            }
            guard values.count > 0 else { return }
            for (field, value) in zip(fields, values) {
                try value.encode(in: &encoder, as: field, runtime: runtime)
            }
        default:
            if fields.count == 1 {
                // A 1-field tuple? try encoding inner content then.
                try encode(in: &encoder, as: fields[0], runtime: runtime)
            } else {
                throw EncodingError.wrongShape(actual: self, expected: id)
            }
        }
    }
    
    func _encodeVariant<E: ScaleCodec.Encoder>(
        id: RuntimeTypeId, variants: [RuntimeTypeVariantItem], runtime: Runtime, in encoder: inout E
    ) throws {
        guard case .variant(let variant) = value else {
            throw EncodingError.wrongShape(actual: self, expected: id)
        }
        guard let varType = variants.first(where: { $0.name == variant.name }) else {
            throw EncodingError.variantNotFound(actual: variant, expected: id)
        }
        try encoder.encode(varType.index, .enumCaseId)
        switch variant {
        case .map(name: _, fields: let map):
            try Value(value: .map(map), context: context)._encodeCompositeFields(
                id: id, fields: varType.fields, runtime: runtime, in: &encoder
            )
        case .sequence(name: _, values: let seq):
            try Value(value: .sequence(seq), context: context)._encodeCompositeFields(
                id: id, fields: varType.fields, runtime: runtime, in: &encoder
            )
        }
    }
    
    func _encodeCompositeFields<E: ScaleCodec.Encoder>(
        id: RuntimeTypeId, fields: [RuntimeTypeField], runtime: Runtime, in encoder: inout E
    ) throws {
        if let map = self.map {
            guard map.count == fields.count else {
                throw EncodingError.mapIsWrongLength(
                    actual: map, expected: id, expectedLen: fields.count
                )
            }
            guard map.count > 0 else { return }
            guard fields[0].name != nil else {
                throw EncodingError.wrongShape(actual: self, expected: id)
            }
            for field in fields {
                let name = field.name! // should be ok. Fields is named
                guard let value = map[name] else {
                    throw EncodingError.mapFieldIsMissing(missingFieldName: name, expected: field.type)
                }
                try value.encode(in: &encoder, as: field.type, runtime: runtime)
            }
        } else {
            let values = self.sequence!
            guard values.count == fields.count else {
                throw EncodingError.sequenceIsWrongLength(
                    actual: values, expected: id, expectedLen: fields.count
                )
            }
            guard values.count > 0 else { return }
            for (field, value) in zip(fields, values) {
                try value.encode(in: &encoder, as: field.type, runtime: runtime)
            }
        }
    }
    
    func _encodePrimitive<E: ScaleCodec.Encoder>(
        id: RuntimeTypeId, type: RuntimeTypePrimitive, in encoder: inout E
    ) throws {
        guard case .primitive(let primitive) = value else {
            throw EncodingError.wrongShape(actual: self, expected: id)
        }
        switch (type, primitive) {
        case (.bool, .bool(let bool)): try encoder.encode(bool)
        case (.char, .char(let char)): try encoder.encode(char)
        case (.str, .string(let str)): try encoder.encode(str)
        case (.u8, let primitive):
            try encoder.encode(_pritimiveToInt(primitive: primitive, id: id, UInt8.self))
        case (.u16, let primitive):
            try encoder.encode(_pritimiveToInt(primitive: primitive, id: id, UInt16.self))
        case (.u32, let primitive):
            try encoder.encode(_pritimiveToInt(primitive: primitive, id: id, UInt32.self))
        case (.u64, let primitive):
            try encoder.encode(_pritimiveToInt(primitive: primitive, id: id, UInt64.self))
        case (.u128, let primitive):
            try encoder.encode(_pritimiveToInt(primitive: primitive, id: id, UInt128.self))
        case (.u256, let primitive):
            try encoder.encode(_pritimiveToInt(primitive: primitive, id: id, UInt256.self))
        case (.i8, let primitive):
            try encoder.encode(_pritimiveToInt(primitive: primitive, id: id, Int8.self))
        case (.i16, let primitive):
            try encoder.encode(_pritimiveToInt(primitive: primitive, id: id, Int16.self))
        case (.i32, let primitive):
            try encoder.encode(_pritimiveToInt(primitive: primitive, id: id, Int32.self))
        case (.i64, let primitive):
            try encoder.encode(_pritimiveToInt(primitive: primitive, id: id, Int64.self))
        case (.i128, let primitive):
            try encoder.encode(_pritimiveToInt(primitive: primitive, id: id, Int128.self))
        case (.i256, let primitive):
            try encoder.encode(_pritimiveToInt(primitive: primitive, id: id, Int256.self))
        default:
            throw EncodingError.wrongShape(actual: self, expected: id)
        }
    }
    
    func _pritimiveToInt<INT: FixedWidthInteger>(
        primitive: Primitive, id: RuntimeTypeId, _ type: INT.Type
    ) throws -> INT {
        switch primitive {
        case .i256(let int):
            guard let val = INT(exactly: int) else {
                throw EncodingError.wrongShape(actual: self, expected: id)
            }
            return val
        case .u256(let int):
            guard let val = INT(exactly: int) else {
                throw EncodingError.wrongShape(actual: self, expected: id)
            }
            return val
        default:
            throw EncodingError.wrongShape(actual: self, expected: id)
        }
    }
    
    func _encodeCompact<E: ScaleCodec.Encoder>(
        id: RuntimeTypeId, type: RuntimeTypeId, runtime: Runtime, in encoder: inout E
    ) throws {
        // Resolve to a primitive type inside the compact encoded type (or fail if
        // we hit some type we wouldn't know how to work with).
        var innerTypeId = type
        var innerType: CompactTy? = nil
        while innerType == nil {
            guard let typeDef = runtime.resolve(type: innerTypeId)?.definition else {
                throw EncodingError.typeNotFound(innerTypeId)
            
            }
            switch typeDef {
            case .composite(fields: let fields):
                guard fields.count == 1 else {
                    throw EncodingError.cannotCompactEncode(innerTypeId)
                }
                innerTypeId = fields[0].type
            case .tuple(components: let vals):
                guard vals.count == 1 else {
                    throw EncodingError.cannotCompactEncode(innerTypeId)
                }
                innerTypeId = vals[0]
            case .primitive(is: let prim):
                switch prim {
                case .u8: innerType = .u8
                case .u16: innerType = .u16
                case .u32: innerType = .u32
                case .u64: innerType = .u64
                case .u128: innerType = .u128
                case .u256: innerType = .u256
                default: throw EncodingError.cannotCompactEncode(innerTypeId)
                }
            default: throw EncodingError.cannotCompactEncode(innerTypeId)
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
                    throw EncodingError.wrongShape(actual: value, expected: innerTypeId)
                }
                value = map.values.first!
            case .sequence(let seq):
                guard seq.count == 1 else {
                    throw EncodingError.wrongShape(actual: value, expected: innerTypeId)
                }
                value = seq.first!
            case .primitive(let primitive):
                innerPrimitive = primitive
            default:
                throw EncodingError.wrongShape(actual: value, expected: innerTypeId)
            }
        }
        // Try to compact encode the primitive type we have into the type asked for:
        switch innerType! {
        case .u8:
            try encoder.encode(
                value._pritimiveToInt(primitive: innerPrimitive!, id: id, UInt8.self),
                .compact
            )
        case .u16:
            try encoder.encode(
                value._pritimiveToInt(primitive: innerPrimitive!, id: id, UInt16.self),
                .compact
            )
        case .u32:
            try encoder.encode(
                value._pritimiveToInt(primitive: innerPrimitive!, id: id, UInt32.self),
                .compact
            )
        case .u64:
            try encoder.encode(
                value._pritimiveToInt(primitive: innerPrimitive!, id: id, UInt64.self),
                .compact
            )
        case .u128:
            try encoder.encode(
                value._pritimiveToInt(primitive: innerPrimitive!, id: id, UInt128.self),
                .compact
            )
        case .u256:
            try encoder.encode(
                value._pritimiveToInt(primitive: innerPrimitive!, id: id, UInt256.self),
                .compact
            )
        }
    }
    
    func _encodeBitSequence<E: ScaleCodec.Encoder>(
        id: RuntimeTypeId, store: RuntimeTypeId, order: RuntimeTypeId,
        runtime: Runtime, in encoder: inout E
    ) throws {
        let format = try BitSequence.Format(store: store, order: order, runtime: runtime)
        switch value {
        case .bitSequence(let seq):
            try encoder.encode(seq, .format(format))
        case .sequence(let values):
            let seq = try values.map {
                guard case .primitive(.bool(let bool)) = $0.value else {
                    throw EncodingError.wrongShape(actual: self, expected: id)
                }
                return bool
            }
            try encoder.encode(BitSequence(seq), .format(format))
        default: throw EncodingError.wrongShape(actual: self, expected: id)
        }
    }
}

extension Value: RuntimeEncodable where C == RuntimeTypeId {
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
        try self.encode(in: &encoder, as: context, runtime: runtime)
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
