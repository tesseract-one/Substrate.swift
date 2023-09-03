//
//  ValidatableType.swift
//  
//
//  Created by Yehor Popovych on 21/08/2023.
//

import Foundation
import ScaleCodec
import Numberick

public protocol ValidatableType {
    static func validate(runtime: any Runtime,
                         type: NetworkType.Info) -> Result<Void, TypeError>
    
    static func validate(runtime: any Runtime,
                         type id: NetworkType.Id) -> Result<NetworkType.Info, TypeError>
}

public enum TypeError: Error {
    case typeNotFound(for: String, id: NetworkType.Id)
    case runtimeTypeLookupFailed(for: String, type: String, reason: Error)
    case wrongType(for: String, got: NetworkType, reason: String)
    case wrongValuesCount(for: String, expected: Int, in: NetworkType)
    case fieldNotFound(for: String, field: String, in: NetworkType)
    case variantNotFound(for: String, variant: String, in: NetworkType)
    case wrongVariantIndex(for: String, variant: String,
                           expected: UInt8, in: NetworkType)
    case wrongVariantFieldsCount(for: String, variant: String,
                                 expected: Int, in: NetworkType)
}

public extension ValidatableType {
    @inlinable
    static func validate(runtime: any Runtime,
                         type id: NetworkType.Id) -> Result<NetworkType.Info, TypeError>
    {
        guard let type = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(for: Self.self, id: id))
        }
        return validate(runtime: runtime, type: id.i(type)).map{type.i(id)}
    }
}

public protocol ComplexValidatableType: ValidatableType {
    associatedtype TypeInfo
    
    static func typeInfo(runtime: any Runtime,
                         type: NetworkType.Info) -> Result<TypeInfo, TypeError>
    static func validate(info: TypeInfo, type: NetworkType.Info,
                         runtime: any Runtime) -> Result<Void, TypeError>
}

public extension ComplexValidatableType {
    @inlinable static func validate(runtime: any Runtime,
                                    type: NetworkType.Info) -> Result<Void, TypeError>
    {
        typeInfo(runtime: runtime, type: type).flatMap {
            validate(info: $0, type: type, runtime: runtime)
        }
    }
}

public protocol ComplexStaticValidatableType: ComplexValidatableType {
    associatedtype ChildTypes
    static var childTypes: ChildTypes { get }
}

public protocol CompositeValidatableType: ComplexValidatableType
    where TypeInfo == [(name: String?, type: NetworkType.Info)] {}

public extension CompositeValidatableType {
    static func typeInfo(runtime: any Runtime,
                         type: NetworkType.Info) -> Result<TypeInfo, TypeError>
    {
        switch type.type.flatten(runtime).definition {
        case .composite(fields: let fs):
            return fs.resultMap {
                guard let type = runtime.resolve(type: $0.type) else {
                    return .failure(.typeNotFound(for: Self.self, id: $0.type))
                }
                return .success(($0.name, type.i($0.type)))
            }
        case .tuple(components: let ids):
            return ids.resultMap {
                guard let type = runtime.resolve(type: $0) else {
                    return .failure(.typeNotFound(for: Self.self, id: $0))
                }
                return .success((nil, $0.i(type)))
            }
        default: return .success([(nil, type)]) // Composite wrapper over simple type
        }
    }
}

public protocol CompositeStaticValidatableType: CompositeValidatableType,
                                                ComplexStaticValidatableType
    where ChildTypes == [ValidatableType.Type] {}

public extension CompositeStaticValidatableType {
    static func validate(info: TypeInfo, type: NetworkType.Info,
                         runtime: any Runtime) -> Result<Void, TypeError>
    {
        let ourFields = childTypes
        guard ourFields.count == info.count else {
            return .failure(.wrongValuesCount(for: Self.self,
                                              expected: ourFields.count,
                                              in: type.type))
        }
        return zip(ourFields, info).voidErrorMap { field, info in
            field.validate(runtime: runtime, type: info.type)
        }
    }
}

public protocol VariantValidatableType: ComplexValidatableType
    where TypeInfo == [(index: UInt8, name: String,
                        fields: [(name: String?, type: NetworkType.Info)])] {}

public extension VariantValidatableType {
    static func typeInfo(runtime: any Runtime,
                         type: NetworkType.Info) -> Result<TypeInfo, TypeError>
    {
        guard case .variant(variants: let variants) = type.type.definition else {
            return .failure(.wrongType(for: Self.self, got: type.type,
                                       reason: "Type isn't Variant"))
        }
        return variants.resultMap { variant in
            return variant.fields.resultMap { field in
                guard let type = runtime.resolve(type: field.type) else {
                    return .failure(.typeNotFound(for: Self.self, id: field.type))
                }
                return .success((field.name, type.i(field.type)))
            }.map { (variant.index, variant.name, $0) }
        }
    }
}

public protocol VariantStaticValidatableType: VariantValidatableType,
                                              ComplexStaticValidatableType
    where ChildTypes == [(index: UInt8, name: String, fields: [ValidatableType.Type])] {}

public extension VariantStaticValidatableType {
    static func validate(info: TypeInfo, type: NetworkType.Info,
                         runtime: any Runtime) -> Result<Void, TypeError>
    {
        let ourVariants = childTypes
        guard ourVariants.count == info.count else {
            return .failure(.wrongValuesCount(for: Self.self,
                                              expected: ourVariants.count,
                                              in: type.type))
        }
        let variantsDict = Dictionary(uniqueKeysWithValues: info.map { ($0.name, $0) })
        return ourVariants.voidErrorMap { variant in
            guard let inVariant = variantsDict[variant.name] else {
                return .failure(.variantNotFound(for: Self.self, variant: variant.name, in: type.type))
            }
            guard variant.index == inVariant.index else {
                return .failure(.wrongVariantIndex(for: Self.self, variant: variant.name,
                                                   expected: variant.index, in: type.type))
            }
            guard variant.fields.count == inVariant.fields.count else {
                return .failure(.wrongVariantFieldsCount(for: Self.self, variant: variant.name,
                                                         expected: variant.fields.count, in: type.type))
            }
            return zip(variant.fields, inVariant.fields).voidErrorMap { field, info in
                field.validate(runtime: runtime, type: info.type)
            }
        }
    }
}

public extension TypeError {
    static func typeNotFound(for type: Any.Type, id: NetworkType.Id) -> Self {
        .typeNotFound(for: String(describing: type), id: id)
    }
    static func runtimeTypeLookupFailed(for t: Any.Type, type: String, reason: Error) -> Self {
        .runtimeTypeLookupFailed(for: String(describing: t), type: type, reason: reason)
    }
    
    static func wrongType(for type: Any.Type, got: NetworkType, reason: String) -> Self {
        .wrongType(for: String(describing: type), got: got, reason: reason)
    }
    static func wrongValuesCount(for type: Any.Type, expected: Int, in: NetworkType) -> Self {
        .wrongValuesCount(for: String(describing: type), expected: expected, in: `in`)
    }
        
    static func fieldNotFound(for type: Any.Type, field: String, in: NetworkType) -> Self {
        .fieldNotFound(for: String(describing: type), field: field, in: `in`)
    }
            
    static func variantNotFound(for type: Any.Type, variant: String, in: NetworkType) -> Self {
        .variantNotFound(for: String(describing: type), variant: variant, in: `in`)
    }
    
    static func wrongVariantFieldsCount(for type: Any.Type, variant: String,
                                        expected: Int, in: NetworkType) -> Self {
        .wrongVariantFieldsCount(for: String(describing: type), variant: variant,
                                 expected: expected, in: `in`)
    }
    
    static func wrongVariantIndex(for type: Any.Type, variant: String,
                                  expected: UInt8, in: NetworkType) -> Self {
        .wrongVariantIndex(for: String(describing: type), variant: variant,
                           expected: expected, in: `in`)
    }
}
