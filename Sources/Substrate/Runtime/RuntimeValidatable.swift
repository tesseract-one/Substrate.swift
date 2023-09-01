//
//  RuntimeValidatable.swift
//  
//
//  Created by Yehor Popovych on 21/08/2023.
//

import Foundation
import ScaleCodec
import Numberick

public protocol RuntimeValidatable {
    static func validate(runtime: any Runtime) -> Result<Void, ValidationError>
}

public protocol RuntimeDynamicValidatable {
    static func validate(runtime: any Runtime,
                         type id: RuntimeType.Id) -> Result<Void, DynamicValidationError>
}

public protocol RuntimeValidatableComposite: RuntimeValidatable {
    static func validatableFieldIds(runtime: any Runtime) -> Result<[RuntimeType.Id], ValidationError>
    static func validate(fields ids: [RuntimeType.Id],
                         runtime: any Runtime) -> Result<Void, ValidationError>
}

public extension RuntimeValidatableComposite {
    static func validate(runtime: any Runtime) -> Result<Void, ValidationError> {
        validatableFieldIds(runtime: runtime).flatMap {
            validate(fields: $0, runtime: runtime)
        }
    }
}

public protocol RuntimeValidatableStaticComposite: RuntimeValidatableComposite {
    static var validatableFields: [any RuntimeDynamicValidatable.Type] { get }
}

public extension RuntimeValidatableStaticComposite {
    static func validate(fields ids: [RuntimeType.Id],
                         runtime: any Runtime) -> Result<Void, ValidationError>
    {
        let ourFields = validatableFields
        guard ourFields.count == ids.count else {
            return .failure(.wrongFieldsCount(for: Self.self,
                                              expected: ourFields.count,
                                              got: ids.count))
        }
        return zip(ourFields, ids).voidErrorMap { field, id in
            field.validate(runtime: runtime, type: id).mapError {
                .childError(for: Self.self, error: $0)
            }
        }
    }
}

public protocol RuntimeDynamicValidatablePrimitive: RuntimeDynamicValidatable {
    static func validate(self: RuntimeType, name: String,
                         primitive: RuntimeType.Primitive) -> Result<Void, DynamicValidationError>
}

public extension RuntimeDynamicValidatablePrimitive {
    static func _validate(runtime: Runtime,
                          type id: RuntimeType.Id) -> Result<RuntimeType, DynamicValidationError>
    {
        guard let info = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(id))
        }
        guard let primitive = info.asPrimitive(runtime) else {
            return .failure(.wrongType(got: info, for: String(describing: Self.self)))
        }
        return validate(self: info, name: String(describing: Self.self),
                        primitive: primitive).map { info }
    }
    
    static func validate(runtime: any Runtime,
                         type id: RuntimeType.Id) -> Result<Void, DynamicValidationError>
    {
        _validate(runtime: runtime, type: id).map {_ in}
    }
}

public protocol RuntimeDynamicValidatableComposite: RuntimeDynamicValidatable {
    static func validate(self: RuntimeType, name: String,
                         fields: [(name: String?, type: RuntimeType.Id)],
                         runtime: any Runtime) -> Result<Void, DynamicValidationError>
}

public extension RuntimeDynamicValidatableComposite {
    static func _validate(runtime: Runtime,
                          type id: RuntimeType.Id) -> Result<RuntimeType, DynamicValidationError>
    {
        guard let info = runtime.resolve(type: id)?.flatten(runtime) else {
            return .failure(.typeNotFound(id))
        }
        let fields: [(name: String?, type: RuntimeType.Id)]
        switch info.definition {
        case .composite(fields: let fs):
            fields = fs.map { ($0.name, $0.type) }
        case .tuple(components: let ids):
            fields = ids.map { (nil, $0) }
        default:
            return .failure(.wrongType(got: info, for: String(describing: Self.self)))
        }
        return validate(self: info, name: String(describing: Self.self),
                        fields: fields, runtime: runtime).map { info }
    }
    
    static func validate(runtime: any Runtime,
                         type id: RuntimeType.Id) -> Result<Void, DynamicValidationError>
    {
        _validate(runtime: runtime, type: id).map {_ in}
    }
}

public protocol RuntimeDynamicValidatableStaticComposite: RuntimeDynamicValidatableComposite {
    static var validatableFields: [any RuntimeDynamicValidatable.Type] { get }
}

public extension RuntimeDynamicValidatableStaticComposite {
    static func validate(self: RuntimeType, name: String,
                         fields: [(name: String?, type: RuntimeType.Id)],
                         runtime: any Runtime) -> Result<Void, DynamicValidationError>
    {
        let ourFields = validatableFields
        guard ourFields.count == fields.count else {
            return .failure(.wrongValuesCount(in: self,
                                              expected: ourFields.count,
                                              for: name))
        }
        return zip(ourFields, fields).voidErrorMap { field, info in
            field.validate(runtime: runtime, type: info.type)
        }
    }
}

public protocol RuntimeDynamicValidatableVariant: RuntimeDynamicValidatable {
    static func validate(self: RuntimeType, name: String,
                         variants: [RuntimeType.VariantItem],
                         runtime: any Runtime) -> Result<Void, DynamicValidationError>
}

public extension RuntimeDynamicValidatableVariant {
    static func _validate(runtime: Runtime,
                          type id: RuntimeType.Id) -> Result<RuntimeType, DynamicValidationError>
    {
        guard let info = runtime.resolve(type: id)?.flatten(runtime) else {
            return .failure(.typeNotFound(id))
        }
        guard case .variant(variants: let variants) = info.definition else {
            return .failure(.wrongType(got: info, for: String(describing: Self.self)))
        }
        return validate(self: info, name: String(describing: Self.self),
                        variants: variants, runtime: runtime).map { info }
    }
    
    static func validate(runtime: any Runtime,
                         type id: RuntimeType.Id) -> Result<Void, DynamicValidationError>
    {
        _validate(runtime: runtime, type: id).map {_ in}
    }
}

public typealias ValidatableStaticVariant = (index: UInt8, name: String,
                                             fields: [any RuntimeDynamicValidatable.Type])

public protocol RuntimeDynamicValidatableStaticVariant: RuntimeDynamicValidatableVariant {
    static var validatableVariants: [ValidatableStaticVariant] { get }
}

public extension RuntimeDynamicValidatableStaticVariant {
    static func validate(self: RuntimeType, name: String,
                         variants: [RuntimeType.VariantItem],
                         runtime: any Runtime) -> Result<Void, DynamicValidationError>
    {
        let ourVariants = validatableVariants
        guard ourVariants.count == variants.count else {
            return .failure(.wrongValuesCount(in: self,
                                              expected: ourVariants.count,
                                              for: name))
        }
        let variantsDict = Dictionary(uniqueKeysWithValues: variants.map { ($0.name, $0) })
        return ourVariants.voidErrorMap { variant in
            guard let inVariant = variantsDict[variant.name] else {
                return .failure(.variantNotFound(name: variant.name, in: self))
            }
            guard variant.index == inVariant.index else {
                return .failure(.wrongType(got: self, for: "\(name).\(variant.name)"))
            }
            guard variant.fields.count == inVariant.fields.count else {
                return .failure(.wrongValuesCount(in: self,
                                                  expected: variant.fields.count,
                                                  for: "\(name).\(variant.name)"))
            }
            return zip(variant.fields, inVariant.fields).voidErrorMap { field, info in
                field.validate(runtime: runtime, type: info.type)
            }
        }
    }
}

public enum ValidationError: Error {
    case childError(for: RuntimeValidatable.Type, error: DynamicValidationError)
    case infoNotFound(for: RuntimeValidatable.Type)
    case wrongFieldsCount(for: RuntimeValidatable.Type, expected: Int, got: Int)
    case paramMismatch(for: RuntimeValidatable.Type, expected: String, got: String)
}

public enum DynamicValidationError: Error {
    case typeNotFound(RuntimeType.Id)
    case runtimeTypeLookupFailed(name: String, reason: Error)
    case wrongType(got: RuntimeType, for: String)
    case wrongValuesCount(in: RuntimeType, expected: Int, for: String)
    case fieldNotFound(name: String, in: RuntimeType)
    case variantNotFound(name: String, in: RuntimeType)
    case typeIdMismatch(got: RuntimeType.Id, has: RuntimeType.Id)
}

public extension CaseIterable where Self: RuntimeDynamicValidatableStaticVariant {
    static var validatableVariants: [ValidatableStaticVariant] {
        allCases.enumerated().map {
            (idx, cs) in (UInt8(idx), String(describing: cs).uppercasedFirst, [])
        }
    }
}

public extension FixedWidthInteger where Self: RuntimeDynamicValidatablePrimitive {
    @inlinable
    static func validate(self: RuntimeType, name: String,
                         primitive: RuntimeType.Primitive) -> Result<Void, DynamicValidationError>
    {
        guard let int = primitive.isAnyInt else {
            return .failure(.wrongType(got: self, for: name))
        }
        guard int.signed == Self.isSigned, int.bits == Self.bitWidth else {
            return .failure(.wrongType(got: self, for: name))
        }
        return .success(())
    }
}

extension UInt8: RuntimeDynamicValidatablePrimitive {}
extension UInt16: RuntimeDynamicValidatablePrimitive {}
extension UInt32: RuntimeDynamicValidatablePrimitive {}
extension UInt64: RuntimeDynamicValidatablePrimitive {}
extension UInt: RuntimeDynamicValidatablePrimitive {}
extension NBKDoubleWidth: RuntimeDynamicValidatablePrimitive {}
extension Int8: RuntimeDynamicValidatablePrimitive {}
extension Int16: RuntimeDynamicValidatablePrimitive {}
extension Int32: RuntimeDynamicValidatablePrimitive {}
extension Int64: RuntimeDynamicValidatablePrimitive {}
extension Int: RuntimeDynamicValidatablePrimitive {}

extension Value: RuntimeDynamicValidatable {
    @inlinable
    public static func validate(runtime: any Runtime,
                                type id: RuntimeType.Id) -> Result<Void, DynamicValidationError>
    {
        .success(())
    }
}

extension Bool: RuntimeDynamicValidatablePrimitive {
    @inlinable
    public static func validate(
        self: RuntimeType, name: String, primitive: RuntimeType.Primitive
    ) -> Result<Void, DynamicValidationError> {
        primitive.isBool ? .success(()) : .failure(.wrongType(got: self, for: name))
    }
}

extension String: RuntimeDynamicValidatablePrimitive {
    @inlinable
    public static func validate(
        self: RuntimeType, name: String, primitive: RuntimeType.Primitive
    ) -> Result<Void, DynamicValidationError> {
        primitive.isString ? .success(()) : .failure(.wrongType(got: self, for: name))
    }
}

extension Data: RuntimeDynamicValidatable {
    public static func validate(runtime: Runtime,
                                type id: RuntimeType.Id) -> Result<Void, DynamicValidationError>
    {
        guard let info = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(id))
        }
        guard info.asBytes(runtime) != nil else {
            return .failure(.wrongType(got: info, for: String(describing: Self.self)))
        }
        return .success(())
    }
}

extension Compact: RuntimeDynamicValidatable {
    public static func validate(runtime: any Runtime,
                                type id: RuntimeType.Id) -> Result<Void, DynamicValidationError>
    {
        guard let info = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(id))
        }
        guard let compact = info.asCompact(runtime) else {
            return .failure(.wrongType(got: info, for: String(describing: Self.self)))
        }
        if let primitive = compact.asPrimitive(runtime) { // Compact<UInt>
            guard let bits = primitive.isUInt else {
                return .failure(.wrongType(got: info, for: String(describing: Self.self)))
            }
            guard bits <= T.compactBitWidth else {
                return .failure(.wrongType(got: info, for: String(describing: Self.self)))
            }
        } else if compact.isEmpty(runtime) { // Compact<()>
            guard T.compactBitWidth == 0 else {
                return .failure(.wrongType(got: info, for: String(describing: Self.self)))
            }
        } else { // Unknown Compact
            return .failure(.wrongType(got: info, for: String(describing: Self.self)))
        }
        
        return .success(())
    }
}

extension Character: RuntimeDynamicValidatablePrimitive {
    @inlinable
    public static func validate(
        self: RuntimeType, name: String, primitive: RuntimeType.Primitive
    ) -> Result<Void, DynamicValidationError> {
        primitive.isChar ? .success(()) : .failure(.wrongType(got: self, for: name))
    }
}

extension Array: RuntimeDynamicValidatable where Element: RuntimeDynamicValidatable {
    public static func validate(runtime: Runtime,
                                type id: RuntimeType.Id) -> Result<Void, DynamicValidationError>
    {
        guard let info = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(id))
        }
        let flat = info.flatten(runtime)
        switch flat.definition {
        case .array(count: _, of: let eType), .sequence(of: let eType):
            return Element.validate(runtime: runtime, type: eType)
        case .composite(fields: let fields):
            for field in fields {
                switch Element.validate(runtime: runtime, type: field.type) {
                case .success(_): continue
                case .failure(let err): return .failure(err)
                }
            }
            return .success(())
        case .tuple(components: let ids):
            for id in ids {
                switch Element.validate(runtime: runtime, type: id) {
                case .success(_): continue
                case .failure(let err): return .failure(err)
                }
            }
            return .success(())
        default:
            return .failure(.wrongType(got: info, for: String(describing: Self.self)))
        }
    }
}

extension Optional: RuntimeDynamicValidatable where Wrapped: RuntimeDynamicValidatable {
    public static func validate(runtime: Runtime,
                                type id: RuntimeType.Id) -> Result<Void, DynamicValidationError>
    {
        guard let info = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(id))
        }
        guard let field = info.asOptional(runtime) else {
            return .failure(.wrongType(got: info, for: String(describing: Self.self)))
        }
        return Wrapped.validate(runtime: runtime, type: field.type)
    }
}

extension Either: RuntimeDynamicValidatable where Left: RuntimeDynamicValidatable, Right: RuntimeDynamicValidatable {
    public static func validate(runtime: Runtime,
                                type id: RuntimeType.Id) -> Result<Void, DynamicValidationError>
    {
        guard let info = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(id))
        }
        guard let result = info.asResult(runtime) else {
            return .failure(.wrongType(got: info, for: String(describing: Self.self)))
        }
        return Left.validate(runtime: runtime, type: result.err.type).flatMap {
            Right.validate(runtime: runtime, type: result.ok.type)
        }
    }
}
