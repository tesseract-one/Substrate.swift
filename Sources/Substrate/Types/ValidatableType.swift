//
//  ValidatableType.swift
//  
//
//  Created by Yehor Popovych on 21/08/2023.
//

import Foundation
import ScaleCodec
import Numberick

public protocol ValidatableTypeDynamic {
    func validate(runtime: any Runtime, type: TypeDefinition) -> Result<Void, TypeError>
}

public protocol ValidatableTypeStatic {
    static func validate(type: TypeDefinition) -> Result<Void, TypeError>
}

public typealias ValidatableType = ValidatableTypeDynamic & ValidatableTypeStatic

public enum TypeError: Error, Hashable, Equatable, CustomDebugStringConvertible {
    case badState(for: String, reason: String, info: ErrorMethodInfo)
    case wrongType(for: String, type: TypeDefinition, reason: String,
                   info: ErrorMethodInfo)
    case wrongValuesCount(for: String, expected: Int, type: TypeDefinition,
                          info: ErrorMethodInfo)
    case fieldNotFound(for: String, field: String, type: TypeDefinition,
                       info: ErrorMethodInfo)
    case variantNotFound(for: String, variant: String, type: TypeDefinition,
                         info: ErrorMethodInfo)
    case wrongVariantIndex(for: String, variant: String,
                           expected: UInt8, type: TypeDefinition,
                           info: ErrorMethodInfo)
    case wrongVariantFieldsCount(for: String, variant: String,
                                 expected: Int, type: TypeDefinition,
                                 info: ErrorMethodInfo)
    
    
    public var debugDescription: String {
        switch self {
        case .badState(for: let fr, reason: let r, info: let i):
            return "\(i):: <\(fr)> :: Bad internal state, reason - \"\(r)\""
        case .wrongType(for: let fr, type: let t, reason: let r, info: let i):
            return "\(i):: <\(fr)> :: Bad type found \"\(t)\", reason - \"\(r)\""
        case .wrongValuesCount(for: let fr, expected: let e, type: let t, info: let i):
            return "\(i):: <\(fr)> :: Different values count, expected \(e), type \(t)"
        case .fieldNotFound(for: let fr, field: let fd, type: let t, info: let i):
            return "\(i):: <\(fr)> :: Field \"\(fd)\" not found, type \(t)"
        case .variantNotFound(for: let fr, variant: let v, type: let t, info: let i):
            return "\(i):: <\(fr)> :: Variant \"\(v)\" not found, type \(t)"
        case .wrongVariantIndex(for: let fr, variant: let v,
                                expected: let e, type: let t, info: let i):
            return "\(i):: <\(fr)> :: Variant \"\(v)\" has wrong index, expected \(e), type \(t)"
        case .wrongVariantFieldsCount(for: let fr, variant: let v,
                                      expected: let e, type: let t, info: let i):
            return "\(i):: <\(fr)> :: Variant \"\(v)\" has wrong fields count, expected \(e), type \(t)"
        }
    }
}

public extension ValidatableTypeStatic {
    @inlinable
    func validate(runtime: any Runtime, type: TypeDefinition) -> Result<Void, TypeError>
    {
        Self.validate(type: type)
    }
}

public protocol ComplexValidatableType: ValidatableType {
    associatedtype TypeInfo
    
    static func parseType(type: TypeDefinition) -> Result<TypeInfo, TypeError>
    static func validate(info: TypeInfo, type: TypeDefinition) -> Result<Void, TypeError>
}

public extension ComplexValidatableType {
    @inlinable static func validate(type: TypeDefinition) -> Result<Void, TypeError>
    {
        parseType(type: type).flatMap { validate(info: $0, type: type) }
    }
}

public protocol ComplexStaticValidatableType: ComplexValidatableType {
    associatedtype ChildTypes
    static var childTypes: ChildTypes { get }
}

public protocol CompositeValidatableType: ComplexValidatableType
    where TypeInfo == [TypeDefinition.Field] {}

public extension CompositeValidatableType {
    static func parseType(type: TypeDefinition) -> Result<TypeInfo, TypeError>
    {
        switch type.flatten().definition {
        case .composite(fields: let fs): return .success(fs)
        default: return .success([.v(type)]) // Composite wrapper over simple type
        }
    }
}

public protocol CompositeStaticValidatableType: CompositeValidatableType,
                                                ComplexStaticValidatableType
    where ChildTypes == [ValidatableTypeStatic.Type] {}

public extension CompositeStaticValidatableType {
    static func validate(info: TypeInfo, type: TypeDefinition) -> Result<Void, TypeError>
    {
        let ourFields = childTypes
        guard ourFields.count == info.count else {
            return .failure(.wrongValuesCount(for: Self.self,
                                              expected: ourFields.count,
                                              type: type, .get()))
        }
        return zip(ourFields, info).voidErrorMap { field, info in
            field.validate(type: *info.type)
        }
    }
}

public protocol VariantValidatableType: ComplexValidatableType
    where TypeInfo == [TypeDefinition.Variant] {}

public extension VariantValidatableType {
    static func parseType(type: TypeDefinition) -> Result<TypeInfo, TypeError>
    {
        guard case .variant(variants: let variants) = type.definition else {
            return .failure(.wrongType(for: Self.self, type: type,
                                       reason: "Type isn't Variant", .get()))
        }
        return .success(variants)
    }
}

public protocol VariantStaticValidatableType: VariantValidatableType,
                                              ComplexStaticValidatableType
    where ChildTypes == [(index: UInt8, name: String, fields: [ValidatableTypeStatic.Type])] {}

public extension VariantStaticValidatableType {
    static func validate(info: TypeInfo, type: TypeDefinition) -> Result<Void, TypeError>
    {
        let ourVariants = childTypes
        guard ourVariants.count == info.count else {
            return .failure(.wrongValuesCount(for: Self.self,
                                              expected: ourVariants.count,
                                              type: type, .get()))
        }
        let variantsDict = Dictionary(uniqueKeysWithValues: info.map { ($0.name, $0) })
        return ourVariants.voidErrorMap { variant in
            guard let inVariant = variantsDict[variant.name] else {
                return .failure(.variantNotFound(for: Self.self,
                                                 variant: variant.name,
                                                 type: type, .get()))
            }
            guard variant.index == inVariant.index else {
                return .failure(.wrongVariantIndex(for: Self.self,
                                                   variant: variant.name,
                                                   expected: variant.index,
                                                   type: type, .get()))
            }
            guard variant.fields.count == inVariant.fields.count else {
                return .failure(.wrongVariantFieldsCount(for: Self.self,
                                                         variant: variant.name,
                                                         expected: variant.fields.count,
                                                         type: type, .get()))
            }
            return zip(variant.fields, inVariant.fields).voidErrorMap { field, info in
                field.validate(type: *info.type)
            }
        }
    }
}

public extension TypeError { // For static validation
    @inlinable
    static func wrongType(for _type: Any.Type, type: TypeDefinition,
                          reason: String, _ info: ErrorMethodInfo) -> Self
    {
        .wrongType(for: String(describing: _type), type: type,
                   reason: reason, info: info)
    }
    
    @inlinable
    static func wrongValuesCount(for _type: Any.Type, expected: Int,
                                 type: TypeDefinition,
                                 _ info: ErrorMethodInfo) -> Self
    {
        .wrongValuesCount(for: String(describing: _type), expected: expected,
                          type: type, info: info)
    }
    
    @inlinable
    static func fieldNotFound(for _type: Any.Type, field: String,
                              type: TypeDefinition, _ info: ErrorMethodInfo) -> Self
    {
        .fieldNotFound(for: String(describing: _type), field: field,
                       type: type, info: info)
    }
    
    @inlinable
    static func variantNotFound(for _type: Any.Type, variant: String,
                                type: TypeDefinition, _ info: ErrorMethodInfo) -> Self
    {
        .variantNotFound(for: String(describing: _type), variant: variant,
                         type: type, info: info)
    }
    
    @inlinable
    static func wrongVariantFieldsCount(for _type: Any.Type, variant: String,
                                        expected: Int, type: TypeDefinition,
                                        _ info: ErrorMethodInfo) -> Self
    {
        .wrongVariantFieldsCount(for: String(describing: _type),
                                 variant: variant, expected: expected,
                                 type: type, info: info)
    }
    
    @inlinable
    static func wrongVariantIndex(for _type: Any.Type, variant: String,
                                  expected: UInt8, type: TypeDefinition,
                                  _ info: ErrorMethodInfo) -> Self
    {
        .wrongVariantIndex(for: String(describing: _type), variant: variant,
                           expected: expected, type: type, info: info)
    }
}

public extension TypeError { // For dynamic validation
    @inlinable
    static func wrongType(for value: Any, type: TypeDefinition,
                          reason: String, _ info: ErrorMethodInfo) -> Self
    {
        .wrongType(for: String(describing: value), type: type,
                   reason: reason, info: info)
    }
    
    @inlinable
    static func wrongValuesCount(for value: Any, expected: Int,
                                 type: TypeDefinition,
                                 _ info: ErrorMethodInfo) -> Self
    {
        .wrongValuesCount(for: String(describing: value), expected: expected,
                          type: type, info: info)
    }
    
    @inlinable
    static func fieldNotFound(for value: Any, field: String,
                              type: TypeDefinition, _ info: ErrorMethodInfo) -> Self
    {
        .fieldNotFound(for: String(describing: value), field: field,
                       type: type, info: info)
    }
    
    @inlinable
    static func variantNotFound(for value: Any, variant: String,
                                type: TypeDefinition, _ info: ErrorMethodInfo) -> Self
    {
        .variantNotFound(for: String(describing: value), variant: variant,
                         type: type, info: info)
    }
    
    @inlinable
    static func wrongVariantFieldsCount(for value: Any, variant: String,
                                        expected: Int, type: TypeDefinition,
                                        _ info: ErrorMethodInfo) -> Self
    {
        .wrongVariantFieldsCount(for: String(describing: value),
                                 variant: variant, expected: expected,
                                 type: type, info: info)
    }
    
    @inlinable
    static func wrongVariantIndex(for value: Any, variant: String,
                                  expected: UInt8, type: TypeDefinition,
                                  _ info: ErrorMethodInfo) -> Self
    {
        .wrongVariantIndex(for: String(describing: value), variant: variant,
                           expected: expected, type: type, info: info)
    }
}
