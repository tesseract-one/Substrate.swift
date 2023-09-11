//
//  Value+Validatable.swift
//  
//
//  Created by Yehor Popovych on 05/09/2023.
//

import Foundation

// Static validation is always good. We can represent all types
extension Value: ValidatableTypeStatic {
    @inlinable
    public static func validate(as type: TypeDefinition,
                                in runtime: any Runtime) -> Result<Void, TypeError>
    {
        .success(())
    }
}

extension Value: ValidatableTypeDynamic {
    public func validate(as type: TypeDefinition,
                         in runtime: any Runtime) -> Result<Void, TypeError>
    {
        return validate(as: type, in: runtime, skip: false)
    }
    
    public func validate(as type: TypeDefinition,
                         in runtime: any Runtime,
                         skip custom: Bool) -> Result<Void, TypeError>
    {
        if !custom, let coder = runtime.dynamicRuntimeCustomCoders[type.objectId] {
            return coder.validate(value: self, as: type, in: runtime)
        }
        switch type.definition {
        case .composite(fields: let fields):
            return _validateComposite(type: type, fields: fields, runtime: runtime)
        case .sequence(of: let seqTypeId):
            return _validateSequence(type: type, valueType: seqTypeId, runtime: runtime)
        case .array(count: let count, of: let arrTypeId):
            return _validateArray(type: type, valueType: arrTypeId, count: count, runtime: runtime)
        case .variant(variants: let variants):
            return _validateVariant(type: type, variants: variants, runtime: runtime)
        case .primitive(is: let primitive):
            return _validatePrimitive(type: type, primitive: primitive)
        case .compact(of: let vType):
            return _validateCompact(type: type, compact: vType)
        case .bitsequence(_):
            return _validateBitSequence(type: type)
        case .void:
            return sequence?.count == 0 ? .success(())
                : .failure(.wrongType(for: self, type: type,
                                      reason: "Isn't empty composite", .get()))
        }
    }
}


private extension Value {
    func _validateComposite(
        type: TypeDefinition, fields: [TypeDefinition.Field], runtime: Runtime
    ) -> Result<Void, TypeError> {
        switch value {
        case .map(let mFields):
            if fields.count == 1 && mFields.count != 1 {
                // The composite we've provided doesn't have 1 field; it has many.
                // perhaps the type we're encoding to is a wrapper type then; let's
                // jump in and try to encode our composite to the contents of it (1
                // field composites are transparent anyway in SCALE terms).
                return validate(as: *fields[0].type, in: runtime, skip: false)
            } else {
                return _validateCompositeFields(type: type, fields: fields, runtime: runtime)
            }
        case .sequence(let values):
            if fields.count == 1 && values.count != 1 {
                // The composite we've provided doesn't have 1 field; it has many.
                // perhaps the type we're encoding to is a wrapper type then; let's
                // jump in and try to encode our composite to the contents of it (1
                // field composites are transparent anyway in SCALE terms).
                return validate(as: *fields[0].type, in: runtime, skip: false)
            } else {
                return _validateCompositeFields(type: type, fields: fields, runtime: runtime)
            }
        default:
            if fields.count == 1 {
                // We didn't provide a composite type, but the composite type we're
                // aiming for has exactly 1 field. Perhaps it's a wrapper type, so let's
                // aim to encode to the contents of it instead (1 field composites are
                // transparent anyway in SCALE terms).
                return validate(as: *fields[0].type, in: runtime, skip: false)
            } else {
                return .failure(.wrongType(for: self, type: type,
                                           reason: "Isn't Composite", .get()))
            }
        }
    }
    
    func _validateSequence(
        type: TypeDefinition, valueType: TypeDefinition.Weak, runtime: Runtime
    ) -> Result<Void, TypeError> {
        switch value {
        case .sequence(let values):
            return values.voidErrorMap { value in
                value.validate(as: *valueType, in: runtime, skip: false)
            }
        case .primitive(let primitive):
            switch primitive {
            case .bytes(_):
                guard case .primitive(is: .u8) = valueType.definition else {
                    return .failure(.wrongType(for: self, type: *valueType,
                                               reason: "Isn't byte", .get()))
                }
                return .success(())
            default:
                return .failure(.wrongType(for: self, type: type,
                                           reason: "Isn't array", .get()))
            }
        default:
            return .failure(.wrongType(for: self, type: type,
                                       reason: "Isn't array", .get()))
        }
    }
    
    func _validateArray(
        type: TypeDefinition, valueType: TypeDefinition.Weak, count: UInt32, runtime: Runtime
    ) -> Result<Void, TypeError> {
        switch value {
        case .sequence(let values):
            guard values.count == count else {
                return .failure(.wrongValuesCount(for: self,
                                                  expected: values.count,
                                                  type: type, .get()))
            }
            return values.voidErrorMap {
                $0.validate(as: *valueType, in: runtime, skip: false)
            }
        case .primitive(let primitive):
            switch primitive {
            case .bytes(let bytes):
                guard bytes.count == count else {
                    return .failure(.wrongValuesCount(for: self,
                                                      expected: bytes.count,
                                                      type: type, .get()))
                }
                guard case .primitive(is: .u8) = valueType.definition else {
                    return .failure(.wrongType(for: self, type: *valueType,
                                               reason: "Isn't byte", .get()))
                }
                return .success(())
            default:
                return .failure(.wrongType(for: self, type: type,
                                           reason: "Isn't array", .get()))
            }
        default:
            return .failure(.wrongType(for: self, type: type,
                                       reason: "Isn't array", .get()))
        }
    }
    
    func _validateVariant(
        type: TypeDefinition, variants: [TypeDefinition.Variant], runtime: Runtime
    ) -> Result<Void, TypeError> {
        guard case .variant(let variant) = value else {
            return .failure(.wrongType(for: self, type: type,
                                       reason: "Isn't Variant", .get()))
        }
        guard let varType = variants.first(where: { $0.name == variant.name }) else {
            return .failure(.variantNotFound(for: self,
                                             variant: variant.name,
                                             type: type, .get()))
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
        type: TypeDefinition, fields: [TypeDefinition.Field], runtime: Runtime
    ) -> Result<Void, TypeError> {
        if let map = self.map {
            guard map.count == fields.count else {
                return .failure(.wrongValuesCount(for: self,
                                                  expected: map.count,
                                                  type: type, .get()))
            }
            guard map.count > 0 else { return .success(()) }
            guard fields[0].name != nil else {
                return .failure(.wrongType(for: self, type: type,
                                           reason: "Isn't map, seems as sequence",
                                           .get()))
            }
            return fields.voidErrorMap { field in
                let name = field.name! // should be ok. Fields is named
                guard let value = map[name] else {
                    return .failure(.fieldNotFound(for: self, field: name,
                                                   type: type, .get()))
                }
                return value.validate(as: *field.type, in: runtime, skip: false)
            }
        } else {
            let values = self.sequence!
            guard values.count == fields.count else {
                return .failure(.wrongValuesCount(for: self,
                                                  expected: values.count,
                                                  type: type, .get()))
            }
            guard values.count > 0 else { return .success(()) }
            return zip(fields, values).voidErrorMap { field, value in
                value.validate(as: *field.type, in: runtime, skip: false)
            }
        }
    }
    
    func _validatePrimitive(
        type: TypeDefinition, primitive: NetworkType.Primitive
    ) -> Result<Void, TypeError> {
        guard case .primitive(let sprimitive) = value else {
            return .failure(.wrongType(for: self, type: type,
                                       reason: "Isn't primitive", .get()))
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
            return .failure(.wrongType(for: self, type: type,
                                       reason: "Can't match primitive", .get()))
        }
    }
    
    func _validatePrimitiveInt<INT: FixedWidthInteger>(
        primitive: Primitive, type: TypeDefinition, _ itype: INT.Type
    ) -> Result<Void, TypeError> {
        switch primitive {
        case .int(let int):
            return INT(exactly: int) != nil
                ? .success(())
                : .failure(.wrongType(for: self, type: type,
                                      reason: "Int overflow", .get()))
        case .uint(let uint):
            return INT(exactly: uint) != nil
                ? .success(())
                : .failure(.wrongType(for: self, type: type,
                                      reason: "Int overflow", .get()))
        default:
            return .failure(.wrongType(for: self, type: type,
                                       reason: "Isn't integer", .get()))
        }
    }
    
    func _validateCompact(type: TypeDefinition, compact: TypeDefinition.Weak) -> Result<Void, TypeError> {
        // Resolve to a primitive type inside the compact encoded type (or fail if
        // we hit some type we wouldn't know how to work with).
        var innerType = compact
        var innerCtType: CompactTy? = nil
        while innerCtType == nil {
            switch innerType.definition {
            case .composite(fields: let fields):
                guard fields.count == 1 else {
                    return .failure(.wrongType(for: self, type: *innerType,
                                               reason: "Isn't compact", .get()))
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
                default: return .failure(.wrongType(for: self, type: *innerType,
                                                    reason: "Primitive isn't compact encodable",
                                                    .get()))
                }
            default: return .failure(.wrongType(for: self, type: *innerType,
                                                reason: "Isn't compact", .get()))
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
                    return .failure(.wrongType(for: self, type: *innerType,
                                               reason: "Isn't 1 value map", .get()))
                }
                value = map.values.first!
            case .sequence(let seq):
                guard seq.count == 1 else {
                    return .failure(.wrongType(for: self, type: *innerType,
                                               reason: "Isn't 1 value sequence", .get()))
                }
                value = seq.first!
            case .primitive(let primitive):
                innerPrimitive = primitive
            default:
                return .failure(.wrongType(for: self, type: *innerType,
                                           reason: "Isn't compact encodable", .get()))
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
    
    func _validateBitSequence(type: TypeDefinition) -> Result<Void, TypeError> {
        switch value {
        case .bitSequence(_): return .success(())
        case .sequence(let vals):
            return vals.voidErrorMap { val in
                val.bool != nil
                    ? .success(())
                    : .failure(.wrongType(for: self, type: type,
                                          reason: "Isn't bool in sequence",
                                          .get()))
            }
        default: return .failure(.wrongType(for: self, type: type,
                                            reason: "Isn't bit sequence",
                                            .get()))
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
