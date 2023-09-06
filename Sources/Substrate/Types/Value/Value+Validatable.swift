//
//  Value+Validatable.swift
//  
//
//  Created by Yehor Popovych on 05/09/2023.
//

import Foundation

// Static validation is always good. We can represent all types
extension Value: ValidatableType {
    @inlinable
    public static func validate(runtime: any Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        .success(())
    }
}

extension Value: DynamicValidatableType {
    public func validate(runtime: any Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        return validate(runtime: runtime, type: info, custom: true)
    }
    
    @inlinable
    public func validate(runtime: any Runtime,
                         type id: NetworkType.Id,
                         custom: Bool) -> Result<Void, TypeError>
    {
        guard let type = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(for: description, id: id))
        }
        return validate(runtime: runtime, type: id.i(type), custom: custom)
    }
    
    public func validate(runtime: any Runtime,
                         type info: NetworkType.Info,
                         custom: Bool) -> Result<Void, TypeError>
    {
        if custom, let coder = runtime.custom(coder: info) {
            return coder.validate(value: self, as: info, runtime: runtime)
        }
        switch info.type.definition {
        case .composite(fields: let fields):
            return _validateComposite(type: info.type, fields: fields, runtime: runtime)
        case .sequence(of: let seqTypeId):
            return _validateSequence(type: info.type, valueType: seqTypeId, runtime: runtime)
        case .array(count: let count, of: let arrTypeId):
            return _validateArray(type: info.type, valueType: arrTypeId, count: count, runtime: runtime)
        case .tuple(components: let fields):
            return _validateTuple(type: info.type, fields: fields, runtime: runtime)
        case .variant(variants: let variants):
            return _validateVariant(type: info.type, variants: variants, runtime: runtime)
        case .primitive(is: let primitive):
            return _validatePrimitive(type: info.type, primitive: primitive)
        case .compact(of: let type):
            return _validateCompact(type: info.type, compact: type, runtime: runtime)
        case .bitsequence(store: let store, order: let order):
            return _validateBitSequence(type: info.type, store: store, order: order, runtime: runtime)
        }
    }
}


private extension Value {
    func _validateComposite(
        type: NetworkType, fields: [NetworkType.Field], runtime: Runtime
    ) -> Result<Void, TypeError> {
        switch value {
        case .map(let mFields):
            if fields.count == 1 && mFields.count != 1 {
                // The composite we've provided doesn't have 1 field; it has many.
                // perhaps the type we're encoding to is a wrapper type then; let's
                // jump in and try to encode our composite to the contents of it (1
                // field composites are transparent anyway in SCALE terms).
                return validate(runtime: runtime, type: fields[0].type, custom: true)
            } else {
                return _validateCompositeFields(type: type, fields: fields, runtime: runtime)
            }
        case .sequence(let values):
            if fields.count == 1 && values.count != 1 {
                // The composite we've provided doesn't have 1 field; it has many.
                // perhaps the type we're encoding to is a wrapper type then; let's
                // jump in and try to encode our composite to the contents of it (1
                // field composites are transparent anyway in SCALE terms).
                return validate(runtime: runtime, type: fields[0].type, custom: true)
            } else {
                return _validateCompositeFields(type: type, fields: fields, runtime: runtime)
            }
        default:
            if fields.count == 1 {
                // We didn't provide a composite type, but the composite type we're
                // aiming for has exactly 1 field. Perhaps it's a wrapper type, so let's
                // aim to encode to the contents of it instead (1 field composites are
                // transparent anyway in SCALE terms).
                return validate(runtime: runtime, type: fields[0].type, custom: true)
            } else {
                return .failure(.wrongType(for: description, got: type, reason: "Isn't Composite"))
            }
        }
    }
    
    func _validateSequence(
        type: NetworkType, valueType: NetworkType.Id, runtime: Runtime
    ) -> Result<Void, TypeError> {
        switch value {
        case .sequence(let values):
            return values.voidErrorMap { value in
                value.validate(runtime: runtime, type: valueType, custom: true)
            }
        case .primitive(let primitive):
            switch primitive {
            case .bytes(_):
                guard let vTypeInfo = runtime.resolve(type: valueType) else {
                    return .failure(.typeNotFound(for: description, id: valueType))
                }
                guard case .primitive(is: .u8) = vTypeInfo.definition else {
                    return .failure(.wrongType(for: description, got: vTypeInfo,
                                               reason: "Isn't byte"))
                }
                return .success(())
            default:
                return .failure(.wrongType(for: description, got: type,
                                           reason: "Isn't array"))
            }
        default:
            return .failure(.wrongType(for: description, got: type,
                                       reason: "Isn't array"))
        }
    }
    
    func _validateArray(
        type: NetworkType, valueType: NetworkType.Id, count: UInt32, runtime: Runtime
    ) -> Result<Void, TypeError> {
        switch value {
        case .sequence(let values):
            guard values.count == count else {
                return .failure(.wrongValuesCount(for: description,
                                                  expected: values.count, in: type))
            }
            return values.voidErrorMap {
                $0.validate(runtime: runtime, type: valueType, custom: true)
            }
        case .primitive(let primitive):
            switch primitive {
            case .bytes(let bytes):
                guard bytes.count == count else {
                    return .failure(.wrongValuesCount(for: description,
                                                      expected: bytes.count,
                                                      in: type))
                }
                guard let vTypeInfo = runtime.resolve(type: valueType) else {
                    return .failure(.typeNotFound(for: description, id: valueType))
                }
                guard case .primitive(is: .u8) = vTypeInfo.definition else {
                    return .failure(.wrongType(for: description, got: type, reason: "Isn't array"))
                }
                return .success(())
            default:
                return .failure(.wrongType(for: description, got: type, reason: "Isn't array"))
            }
        default:
            return .failure(.wrongType(for: description, got: type, reason: "Isn't array"))
        }
    }
    
    func _validateTuple(
        type: NetworkType, fields: [NetworkType.Id], runtime: Runtime
    ) -> Result<Void, TypeError> {
        switch value {
        case .sequence(let values):
            guard values.count == fields.count else {
                return .failure(.wrongValuesCount(for: description,
                                                  expected: values.count,
                                                  in: type))
            }
            guard values.count > 0 else { return .success(())}
            return zip(fields, values).voidErrorMap { field, value in
                value.validate(runtime: runtime, type: field, custom: true)
            }
        default:
            if fields.count == 1 {
                // A 1-field tuple? try validate inner content then.
                return validate(runtime: runtime, type: fields[0], custom: true)
            } else {
                return .failure(.wrongType(for: description, got: type,
                                           reason: "Isn't array"))
            }
        }
    }
    
    func _validateVariant(
        type: NetworkType, variants: [NetworkType.Variant], runtime: Runtime
    ) -> Result<Void, TypeError> {
        guard case .variant(let variant) = value else {
            return .failure(.wrongType(for: description, got: type, reason: "Isn't Variant"))
        }
        guard let varType = variants.first(where: { $0.name == variant.name }) else {
            return .failure(.variantNotFound(for: description, variant: variant.name, in: type))
        }
        switch variant {
        case .map(name: _, fields: let map):
            return Value(value: .map(map), context: context)._validateCompositeFields(
                type: type, fields: varType.fields, runtime: runtime
            )
        case .sequence(name: _, values: let seq):
            return Value(value: .sequence(seq), context: context)._validateCompositeFields(
                type: type, fields: varType.fields, runtime: runtime
            )
        }
    }
    
    func _validateCompositeFields(
        type: NetworkType, fields: [NetworkType.Field], runtime: Runtime
    ) -> Result<Void, TypeError> {
        if let map = self.map {
            guard map.count == fields.count else {
                return .failure(.wrongValuesCount(for: description,
                                                  expected: map.count, in: type))
            }
            guard map.count > 0 else { return .success(()) }
            guard fields[0].name != nil else {
                return .failure(.wrongType(for: description, got: type,
                                           reason: "Isn't map, seems as sequence"))
            }
            return fields.voidErrorMap { field in
                let name = field.name! // should be ok. Fields is named
                guard let value = map[name] else {
                    return .failure(.fieldNotFound(for: description, field: name, in: type))
                }
                return value.validate(runtime: runtime, type: field.type, custom: true)
            }
        } else {
            let values = self.sequence!
            guard values.count == fields.count else {
                return .failure(.wrongValuesCount(for: description,
                                                  expected: values.count, in: type))
            }
            guard values.count > 0 else { return .success(()) }
            return zip(fields, values).voidErrorMap { field, value in
                value.validate(runtime: runtime, type: field.type, custom: true)
            }
        }
    }
    
    func _validatePrimitive(
        type: NetworkType, primitive: NetworkType.Primitive
    ) -> Result<Void, TypeError> {
        guard case .primitive(let sprimitive) = value else {
            return .failure(.wrongType(for: description, got: type,
                                       reason: "Isn't primitive"))
        }
        switch (primitive, sprimitive) {
        case (.bool, .bool(_)): return .success(())
        case (.char, .char(_)): return .success(())
        case (.str, .string(_)): return .success(())
        case (.u8, let p):
            return _validatePrimitiveInt(primitive: p, type: type, UInt8.self)
        case (.u16, let p):
            return _validatePrimitiveInt(primitive: p, type: type, UInt16.self)
        case (.u32, let p):
            return _validatePrimitiveInt(primitive: p, type: type, UInt32.self)
        case (.u64, let p):
            return _validatePrimitiveInt(primitive: p, type: type, UInt64.self)
        case (.u128, let p):
            return _validatePrimitiveInt(primitive: p, type: type, UInt128.self)
        case (.u256, let p):
            return _validatePrimitiveInt(primitive: p, type: type, UInt256.self)
        case (.i8, let p):
            return _validatePrimitiveInt(primitive: p, type: type, Int8.self)
        case (.i16, let p):
            return _validatePrimitiveInt(primitive: p, type: type, Int16.self)
        case (.i32, let p):
            return _validatePrimitiveInt(primitive: p, type: type, Int32.self)
        case (.i64, let p):
            return _validatePrimitiveInt(primitive: p, type: type, Int64.self)
        case (.i128, let p):
            return _validatePrimitiveInt(primitive: p, type: type, Int128.self)
        case (.i256, let p):
            return _validatePrimitiveInt(primitive: p, type: type, Int256.self)
        default:
            return .failure(.wrongType(for: description, got: type,
                                       reason: "Can't match primitive"))
        }
    }
    
    func _validatePrimitiveInt<INT: FixedWidthInteger>(
        primitive: Primitive, type: NetworkType, _ itype: INT.Type
    ) -> Result<Void, TypeError> {
        switch primitive {
        case .int(let int):
            return INT(exactly: int) != nil
                ? .success(())
                : .failure(.wrongType(for: description, got: type, reason: "Int overflow"))
        case .uint(let uint):
            return INT(exactly: uint) != nil
                ? .success(())
                : .failure(.wrongType(for: description, got: type, reason: "Int overflow"))
        default:
            return .failure(.wrongType(for: description, got: type,
                                       reason: "Isn't integer"))
        }
    }
    
    func _validateCompact(
        type: NetworkType, compact: NetworkType.Id, runtime: Runtime
    ) -> Result<Void, TypeError> {
        // Resolve to a primitive type inside the compact encoded type (or fail if
        // we hit some type we wouldn't know how to work with).
        var innerTypeId = compact
        var innerType: NetworkType!
        var innerCtType: CompactTy? = nil
        while innerCtType == nil {
            guard let type = runtime.resolve(type: innerTypeId) else {
                return .failure(.typeNotFound(for: description, id: innerTypeId))
            }
            innerType = type
            switch innerType.definition {
            case .composite(fields: let fields):
                guard fields.count == 1 else {
                    return .failure(.wrongType(for: description, got: innerType,
                                               reason: "Isn't compact"))
                }
                innerTypeId = fields[0].type
            case .tuple(components: let vals):
                guard vals.count == 1 else {
                    return .failure(.wrongType(for: description, got: innerType,
                                               reason: "Isn't compact"))
                }
                innerTypeId = vals[0]
            case .primitive(is: let prim):
                switch prim {
                case .u8: innerCtType = .u8
                case .u16: innerCtType = .u16
                case .u32: innerCtType = .u32
                case .u64: innerCtType = .u64
                case .u128: innerCtType = .u128
                case .u256: innerCtType = .u256
                default: return .failure(.wrongType(for: description, got: innerType,
                                                    reason: "Primitive isn't compact encodable"))
                }
            default: return .failure(.wrongType(for: description, got: innerType,
                                                reason: "Isn't compact"))
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
                    return .failure(.wrongType(for: description, got: innerType,
                                               reason: "Isn't 1 value map"))
                }
                value = map.values.first!
            case .sequence(let seq):
                guard seq.count == 1 else {
                    return .failure(.wrongType(for: description, got: innerType,
                                               reason: "Isn't 1 value sequence"))
                }
                value = seq.first!
            case .primitive(let primitive):
                innerPrimitive = primitive
            default:
                return .failure(.wrongType(for: description, got: innerType,
                                                    reason: "Isn't compact encodable"))
            }
        }
        // Try to compact encode the primitive type we have into the type asked for:
        switch innerCtType! {
        case .u8:
            return _validatePrimitiveInt(primitive: innerPrimitive!,
                                         type: type, UInt8.self)
        case .u16:
            return _validatePrimitiveInt(primitive: innerPrimitive!,
                                         type: type, UInt16.self)
        case .u32:
            return _validatePrimitiveInt(primitive: innerPrimitive!,
                                         type: type, UInt32.self)
        case .u64:
            return _validatePrimitiveInt(primitive: innerPrimitive!,
                                         type: type, UInt64.self)
        case .u128:
            return _validatePrimitiveInt(primitive: innerPrimitive!,
                                         type: type, UInt128.self)
        case .u256:
            return _validatePrimitiveInt(primitive: innerPrimitive!,
                                         type: type, UInt256.self)
        }
    }
    
    func _validateBitSequence(
        type: NetworkType, store: NetworkType.Id, order: NetworkType.Id, runtime: Runtime
    ) -> Result<Void, TypeError> {
        BitSequence.Format.from(store: store, order: order, runtime: runtime).flatMap { _ in
            switch value {
            case .bitSequence(_): return .success(())
            case .sequence(let vals):
                return vals.voidErrorMap {
                    $0.bool != nil
                    ? .success(())
                    : .failure(.wrongType(for: description, got: type,
                                          reason: "Isn't bool in sequence"))
                }
            default: return .failure(.wrongType(for: description, got: type,
                                                reason: "Isn't bit sequence"))
            }
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
