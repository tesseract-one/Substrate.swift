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
    func validate(runtime: any Runtime,
                  type info: NetworkType.Info) -> Result<Void, TypeError>
    
    func validate(runtime: any Runtime,
                  type id: NetworkType.Id) -> Result<NetworkType.Info, TypeError>
}

public protocol ValidatableTypeStatic {
    static func validate(runtime: any Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError>
    
    static func validate(runtime: any Runtime,
                         type id: NetworkType.Id) -> Result<NetworkType.Info, TypeError>
}

public typealias ValidatableType = ValidatableTypeDynamic & ValidatableTypeStatic

public enum TypeError: Error, Hashable, Equatable, CustomDebugStringConvertible {
    case typeNotFound(for: String, id: NetworkType.Id,
                      info: ErrorMethodInfo)
    case recursiveType(for: String, info: ErrorMethodInfo)
    case wrongType(for: String, type: NetworkType, reason: String,
                   info: ErrorMethodInfo)
    case wrongValuesCount(for: String, expected: Int, type: NetworkType,
                          info: ErrorMethodInfo)
    case fieldNotFound(for: String, field: String, type: NetworkType,
                       info: ErrorMethodInfo)
    case variantNotFound(for: String, variant: String, type: NetworkType,
                         info: ErrorMethodInfo)
    case wrongVariantIndex(for: String, variant: String,
                           expected: UInt8, type: NetworkType,
                           info: ErrorMethodInfo)
    case wrongVariantFieldsCount(for: String, variant: String,
                                 expected: Int, type: NetworkType,
                                 info: ErrorMethodInfo)
    
    
    public var debugDescription: String {
        switch self {
        case .typeNotFound(for: let fr, id: let id, info: let i):
            return "\(i):: <\(fr)> :: Type \(id) not found in runtime"
        case .recursiveType(for: let fr, info: let i):
            return "\(i):: <\(fr)> :: Recursive type definition"
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

public extension ValidatableTypeDynamic {
    @inlinable
    func validate(runtime: any Runtime,
                  type id: NetworkType.Id) -> Result<NetworkType.Info, TypeError>
    {
        guard let type = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(for: Self.self, id: id, .get()))
        }
        return validate(runtime: runtime, type: id.i(type)).map{id.i(type)}
    }
}

public extension ValidatableTypeStatic {
    @inlinable
    func validate(runtime: any Runtime,
                  type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        Self.validate(runtime: runtime, type: info)
    }
    
    @inlinable
    static func validate(runtime: any Runtime,
                         type id: NetworkType.Id) -> Result<NetworkType.Info, TypeError>
    {
        guard let type = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(for: Self.self, id: id, .get()))
        }
        return validate(runtime: runtime, type: id.i(type)).map{type.i(id)}
    }
}

public protocol ComplexValidatableType: ValidatableTypeStatic {
    associatedtype TypeInfo
    
    static func typeInfo(runtime: any Runtime,
                         type: NetworkType.Info) -> Result<TypeInfo, TypeError>
    static func validate(info sinfo: TypeInfo, type tinfo: NetworkType.Info,
                         runtime: any Runtime) -> Result<Void, TypeError>
}

public extension ComplexValidatableType {
    @inlinable static func validate(runtime: any Runtime,
                                    type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        typeInfo(runtime: runtime, type: info).flatMap {
            validate(info: $0, type: info, runtime: runtime)
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
                         type info: NetworkType.Info) -> Result<TypeInfo, TypeError>
    {
        switch info.type.flatten(runtime).definition {
        case .composite(fields: let fs):
            return fs.resultMap {
                guard let type = runtime.resolve(type: $0.type) else {
                    return .failure(.typeNotFound(for: Self.self, id: $0.type, .get()))
                }
                return .success(($0.name, type.i($0.type)))
            }
        case .tuple(components: let ids):
            return ids.resultMap {
                guard let type = runtime.resolve(type: $0) else {
                    return .failure(.typeNotFound(for: Self.self, id: $0, .get()))
                }
                return .success((nil, $0.i(type)))
            }
        default: return .success([(nil, info)]) // Composite wrapper over simple type
        }
    }
}

public protocol CompositeStaticValidatableType: CompositeValidatableType,
                                                ComplexStaticValidatableType
    where ChildTypes == [ValidatableTypeStatic.Type] {}

public extension CompositeStaticValidatableType {
    static func validate(info sinfo: TypeInfo, type tinfo: NetworkType.Info,
                         runtime: any Runtime) -> Result<Void, TypeError>
    {
        let ourFields = childTypes
        guard ourFields.count == sinfo.count else {
            return .failure(.wrongValuesCount(for: Self.self,
                                              expected: ourFields.count,
                                              type: tinfo.type, .get()))
        }
        return zip(ourFields, sinfo).voidErrorMap { field, info in
            field.validate(runtime: runtime, type: info.type)
        }
    }
}

public protocol VariantValidatableType: ComplexValidatableType
    where TypeInfo == [(index: UInt8, name: String,
                        fields: [(name: String?, type: NetworkType.Info)])] {}

public extension VariantValidatableType {
    static func typeInfo(runtime: any Runtime,
                         type info: NetworkType.Info) -> Result<TypeInfo, TypeError>
    {
        guard case .variant(variants: let variants) = info.type.definition else {
            return .failure(.wrongType(for: Self.self, type: info.type,
                                       reason: "Type isn't Variant", .get()))
        }
        return variants.resultMap { variant in
            return variant.fields.resultMap { field in
                guard let type = runtime.resolve(type: field.type) else {
                    return .failure(.typeNotFound(for: Self.self, id: field.type, .get()))
                }
                return .success((field.name, type.i(field.type)))
            }.map { (variant.index, variant.name, $0) }
        }
    }
}

public protocol VariantStaticValidatableType: VariantValidatableType,
                                              ComplexStaticValidatableType
    where ChildTypes == [(index: UInt8, name: String, fields: [ValidatableTypeStatic.Type])] {}

public extension VariantStaticValidatableType {
    static func validate(info sinfo: TypeInfo, type tinfo: NetworkType.Info,
                         runtime: any Runtime) -> Result<Void, TypeError>
    {
        let ourVariants = childTypes
        guard ourVariants.count == sinfo.count else {
            return .failure(.wrongValuesCount(for: Self.self,
                                              expected: ourVariants.count,
                                              type: tinfo.type, .get()))
        }
        let variantsDict = Dictionary(uniqueKeysWithValues: sinfo.map { ($0.name, $0) })
        return ourVariants.voidErrorMap { variant in
            guard let inVariant = variantsDict[variant.name] else {
                return .failure(.variantNotFound(for: Self.self,
                                                 variant: variant.name,
                                                 type: tinfo.type, .get()))
            }
            guard variant.index == inVariant.index else {
                return .failure(.wrongVariantIndex(for: Self.self,
                                                   variant: variant.name,
                                                   expected: variant.index,
                                                   type: tinfo.type, .get()))
            }
            guard variant.fields.count == inVariant.fields.count else {
                return .failure(.wrongVariantFieldsCount(for: Self.self,
                                                         variant: variant.name,
                                                         expected: variant.fields.count,
                                                         type: tinfo.type, .get()))
            }
            return zip(variant.fields, inVariant.fields).voidErrorMap { field, info in
                field.validate(runtime: runtime, type: info.type)
            }
        }
    }
}

public extension TypeError { // For static validation
    @inlinable
    static func typeNotFound(for _type: Any.Type, id: NetworkType.Id,
                             _ info: ErrorMethodInfo) -> Self
    {
        .typeNotFound(for: String(describing: _type), id: id, info: info)
    }
    
    @inlinable
    static func wrongType(for _type: Any.Type, type: NetworkType,
                          reason: String, _ info: ErrorMethodInfo) -> Self
    {
        .wrongType(for: String(describing: _type), type: type,
                   reason: reason, info: info)
    }
    
    @inlinable
    static func wrongValuesCount(for _type: Any.Type, expected: Int,
                                 type: NetworkType,
                                 _ info: ErrorMethodInfo) -> Self
    {
        .wrongValuesCount(for: String(describing: _type), expected: expected,
                          type: type, info: info)
    }
    
    @inlinable
    static func fieldNotFound(for _type: Any.Type, field: String,
                              type: NetworkType, _ info: ErrorMethodInfo) -> Self
    {
        .fieldNotFound(for: String(describing: _type), field: field,
                       type: type, info: info)
    }
    
    @inlinable
    static func variantNotFound(for _type: Any.Type, variant: String,
                                type: NetworkType, _ info: ErrorMethodInfo) -> Self
    {
        .variantNotFound(for: String(describing: _type), variant: variant,
                         type: type, info: info)
    }
    
    @inlinable
    static func wrongVariantFieldsCount(for _type: Any.Type, variant: String,
                                        expected: Int, type: NetworkType,
                                        _ info: ErrorMethodInfo) -> Self
    {
        .wrongVariantFieldsCount(for: String(describing: _type),
                                 variant: variant, expected: expected,
                                 type: type, info: info)
    }
    
    @inlinable
    static func wrongVariantIndex(for _type: Any.Type, variant: String,
                                  expected: UInt8, type: NetworkType,
                                  _ info: ErrorMethodInfo) -> Self
    {
        .wrongVariantIndex(for: String(describing: _type), variant: variant,
                           expected: expected, type: type, info: info)
    }
}

public extension TypeError { // For static validation
    @inlinable
    static func typeNotFound(for value: Any, id: NetworkType.Id,
                             _ info: ErrorMethodInfo) -> Self
    {
        .typeNotFound(for: String(describing: value), id: id, info: info)
    }
    
    @inlinable
    static func wrongType(for value: Any, type: NetworkType,
                          reason: String, _ info: ErrorMethodInfo) -> Self
    {
        .wrongType(for: String(describing: value), type: type,
                   reason: reason, info: info)
    }
    
    @inlinable
    static func wrongValuesCount(for value: Any, expected: Int,
                                 type: NetworkType,
                                 _ info: ErrorMethodInfo) -> Self
    {
        .wrongValuesCount(for: String(describing: value), expected: expected,
                          type: type, info: info)
    }
    
    @inlinable
    static func fieldNotFound(for value: Any, field: String,
                              type: NetworkType, _ info: ErrorMethodInfo) -> Self
    {
        .fieldNotFound(for: String(describing: value), field: field,
                       type: type, info: info)
    }
    
    @inlinable
    static func variantNotFound(for value: Any, variant: String,
                                type: NetworkType, _ info: ErrorMethodInfo) -> Self
    {
        .variantNotFound(for: String(describing: value), variant: variant,
                         type: type, info: info)
    }
    
    @inlinable
    static func wrongVariantFieldsCount(for value: Any, variant: String,
                                        expected: Int, type: NetworkType,
                                        _ info: ErrorMethodInfo) -> Self
    {
        .wrongVariantFieldsCount(for: String(describing: value),
                                 variant: variant, expected: expected,
                                 type: type, info: info)
    }
    
    @inlinable
    static func wrongVariantIndex(for value: Any, variant: String,
                                  expected: UInt8, type: NetworkType,
                                  _ info: ErrorMethodInfo) -> Self
    {
        .wrongVariantIndex(for: String(describing: value), variant: variant,
                           expected: expected, type: type, info: info)
    }
}
