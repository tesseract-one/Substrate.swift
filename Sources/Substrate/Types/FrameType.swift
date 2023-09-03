//
//  FrameType.swift
//  
//
//  Created by Yehor Popovych on 02/09/2023.
//

import Foundation

public protocol FrameType {
    static var frame: String { get }
    static var name: String { get }
    static var frameTypeName: String { get }
    
    static func validate(runtime: any Runtime) -> Result<Void, FrameTypeError>
}

public extension FrameType {
    var name: String { Self.name }
    var frame: String { Self.frame }
}

public enum FrameTypeError: Error {
    case typeInfoNotFound(for: String)
    case typeInfoNotFound(for: String, index: UInt8, frame: UInt8)
    case foundWrongType(for: String, found: (name: String, frame: String))
    case wrongFieldsCount(for: String, expected: Int, got: Int)
    case paramMismatch(for: String, index: Int, expected: String, got: String)
    case valueNotFound(for: String, key: String)
    case childError(for: String, index: Int, error: TypeError)
}

public enum FrameTypeDefinition {
    case call(FrameType.Type, fields: [TypeDefinition.Field])
    case event(FrameType.Type, fields: [TypeDefinition.Field])
    case constant(FrameType.Type, type: TypeDefinition)
    case runtime(FrameType.Type, params: [TypeDefinition.Field], return: TypeDefinition)
    case storage(FrameType.Type,
                 keys: [(key: TypeDefinition, hasher: LastMetadata.StorageHasher)],
                 value: TypeDefinition)
}


public protocol ComplexFrameType: FrameType {
    associatedtype TypeInfo
    
    static func typeInfo(runtime: any Runtime) -> Result<TypeInfo, FrameTypeError>
    static func validate(info: TypeInfo, runtime: any Runtime) -> Result<Void, FrameTypeError>
}

public extension ComplexFrameType {
    @inlinable static func validate(runtime: any Runtime) -> Result<Void, FrameTypeError> {
        typeInfo(runtime: runtime).flatMap { validate(info: $0, runtime: runtime) }
    }
}

public protocol ComplexStaticFrameType: ComplexFrameType {
    associatedtype ChildTypes
    static var childTypes: ChildTypes { get }
}

// Call & Event
public extension ComplexStaticFrameType where
    TypeInfo == EventTypeInfo, ChildTypes == EventChildTypes
{
    static func validate(info: TypeInfo,
                         runtime: any Runtime) -> Result<Void, FrameTypeError>
    {
        let ourTypes = childTypes
        guard ourTypes.count == info.count else {
            return .failure(.wrongFieldsCount(for: Self.self, expected: ourTypes.count,
                                              got: info.count))
        }
        return zip(ourTypes, info).enumerated().voidErrorMap { index, zip in
            let (our, info) = zip
            return our.validate(runtime: runtime, type: info.type.i(info.field.type)).mapError {
                .childError(for: Self.self, index: index, error: $0)
            }
        }
    }
}

public protocol IdentifiableFrameType: FrameType {
    static var definition: FrameTypeDefinition { get }
}

public extension IdentifiableFrameType {
    static func validate(runtime: any Runtime) -> Result<Void, FrameTypeError>
    {
        definition.validate(type: Self.self, runtime: runtime)
    }
}

public extension FrameTypeDefinition {
    func validate(type: any IdentifiableFrameType.Type,
                  runtime: any Runtime) -> Result<Void, FrameTypeError>
    {
        switch self {
        case .call(let ftype, fields: let fields):
            guard let info = runtime.resolve(callParams: ftype.name, pallet: ftype.frame) else {
                return .failure(.typeInfoNotFound(for: type))
            }
            return validate(fields: fields,
                            ifields: info.map{($0.field.name, $0.type.i($0.field.type))},
                            type: type, runtime: runtime)
        case .event(let ftype, fields: let fields):
            guard let info = runtime.resolve(eventParams: ftype.name, pallet: ftype.frame) else {
                return .failure(.typeInfoNotFound(for: type))
            }
            return validate(fields: fields,
                            ifields: info.map{($0.field.name, $0.type.i($0.field.type))},
                            type: type, runtime: runtime)
        case .runtime(let ftype, params: let params, return: let rtype):
            guard let info = runtime.resolve(runtimeCall: ftype.name, api: ftype.frame) else {
                return .failure(.typeInfoNotFound(for: type))
            }
            return validate(fields: params, ifields: info.params,
                            type: type, runtime: runtime).flatMap {
                return rtype.validate(runtime: runtime, type: info.result.type).mapError {
                    .childError(for: type, index: -1, error: $0)
                }
            }
        case .constant(let ftype, type: let vtype):
            guard let info = runtime.resolve(constant: ftype.name, pallet: ftype.frame) else {
                return .failure(.typeInfoNotFound(for: type))
            }
            return vtype.validate(runtime: runtime, type: info.type.type).mapError {
                .childError(for: type, index: -1, error: $0)
            }
        case .storage(let ftype, keys: let path, value: let vtype):
            guard let info = runtime.resolve(storage: ftype.name, pallet: ftype.frame) else {
                return .failure(.typeInfoNotFound(for: type))
            }
            guard path.count == info.keys.count else {
                return .failure(.wrongFieldsCount(for: type, expected: path.count,
                                                  got: info.keys.count))
            }
            return zip(path, info.keys).enumerated().voidErrorMap { index, zip in
                let (pkey, ikey) = zip
                guard pkey.hasher == ikey.hasher else {
                    return .failure(.paramMismatch(for: type, index: index,
                                                   expected: pkey.hasher.description,
                                                   got: ikey.hasher.description))
                }
                return pkey.key.validate(runtime: runtime, type: ikey.type.type)
                    .mapError { .childError(for: type, index: index, error: $0) }
            }.flatMap {
                vtype.validate(runtime: runtime, type: info.value.type).mapError {
                    .childError(for: type, index: -1, error: $0)
                }
            }
        }
    }
    
    func validate(fields: [TypeDefinition.Field],
                  ifields: [(name: String?, type: NetworkType.Info)],
                  type: any IdentifiableFrameType.Type,
                  runtime: any Runtime) -> Result<Void, FrameTypeError>
    {
        guard fields.count == ifields.count else {
            return .failure(.wrongFieldsCount(for: type, expected: fields.count, got: ifields.count))
        }
        return zip(fields, ifields).enumerated().voidErrorMap { index, zip in
            let (field, info) = zip
            return field.type.validate(runtime: runtime, type: info.type.type).mapError {
                .childError(for: type, index: index, error: $0)
            }
        }
    }
}

public extension FrameTypeError { // FrameType
    @inlinable
    static func typeInfoNotFound(for type: FrameType.Type) -> Self {
        .typeInfoNotFound(for: "\(type.frameTypeName): \(type.frame).\(type.name)")
    }
    
    @inlinable
    static func typeInfoNotFound(for type: FrameType.Type,
                                 index: UInt8, frame: UInt8) -> Self {
        .typeInfoNotFound(for: "\(type.frameTypeName): \(type.frame).\(type.name)",
                          index: index, frame: frame)
    }
    
    @inlinable
    static func foundWrongType(for type: FrameType.Type,
                               name: String, frame: String) -> Self {
        .foundWrongType(for: "\(type.frameTypeName): \(type.frame).\(type.name)",
                        found: (name, frame))
    }
    
    @inlinable
    static func wrongFieldsCount(for type: FrameType.Type,
                                 expected: Int, got: Int) -> Self {
        .wrongFieldsCount(for: "\(type.frameTypeName): \(type.frame).\(type.name)",
                          expected: expected, got: got)
    }
    
    @inlinable
    static func paramMismatch(for type: FrameType.Type, index: Int,
                              expected: Any, got: Any) -> Self {
        .paramMismatch(for: "\(type.frameTypeName): \(type.frame).\(type.name)",
                       index: index,
                       expected: String(describing: expected),
                       got: String(describing: got))
    }
    
    @inlinable
    static func valueNotFound(for type: FrameType.Type, key: String) -> Self {
        .valueNotFound(for: "\(type.frameTypeName): \(type.frame).\(type.name)",
                       key: key)
    }
    
    @inlinable
    static func childError(for type: FrameType.Type,
                           index: Int, error: TypeError) -> Self {
        .childError(for: "\(type.frameTypeName): \(type.frame).\(type.name)",
                    index: index, error: error)
    }
}
