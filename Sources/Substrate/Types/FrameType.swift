//
//  FrameType.swift
//  
//
//  Created by Yehor Popovych on 02/09/2023.
//

import Foundation

public protocol FrameType: RuntimeValidatableType {
    static var frame: String { get }
    static var name: String { get }
    static var frameTypeName: String { get }
    
    static func validate(runtime: any Runtime) -> Result<Void, FrameTypeError>
}

public extension FrameType {
    @inlinable var name: String { Self.name }
    @inlinable var frame: String { Self.frame }
    
    @inlinable
    static var errorTypeName: String { "\(frameTypeName): \(frame).\(name)" }
    
    @inlinable
    func validate(runtime: any Runtime) -> Result<Void, FrameTypeError> {
        Self.validate(runtime: runtime)
    }
}

public enum FrameTypeError: Error {
    case typeInfoNotFound(for: String, _ info: ErrorMethodInfo)
    case typeInfoNotFound(for: String, index: UInt8,
                          frame: UInt8, _ info: ErrorMethodInfo)
    case foundWrongType(for: String, found: (name: String, frame: String),
                        _ info: ErrorMethodInfo)
    case wrongType(for: String, got: String, reason: String,
                   _ info: ErrorMethodInfo)
    case wrongFieldsCount(for: String, expected: Int, got: Int,
                          _ info: ErrorMethodInfo)
    case paramMismatch(for: String, index: Int, expected: String,
                       got: String, _ info: ErrorMethodInfo)
    case valueNotFound(for: String, key: String, _ info: ErrorMethodInfo)
    case childError(for: String, index: Int,
                    error: TypeError, _ info: ErrorMethodInfo)
}

public enum FrameTypeDefinition {
    case call(fields: [TypeDefinition.Field])
    case event(fields: [TypeDefinition.Field])
    case constant(type: TypeDefinition)
    case runtimeCall(params: [TypeDefinition.Field], return: TypeDefinition)
    case storage(keys: StorageKeyTypeKeysInfo, value: TypeDefinition)
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
                                              got: info.count, .get()))
        }
        return zip(ourTypes, info).enumerated().voidErrorMap { index, zip in
            let (our, info) = zip
            return our.validate(type: *info.type).mapError {
                .childError(for: Self.self, index: index, error: $0, .get())
            }
        }
    }
}

public protocol IdentifiableFrameType: FrameType {
    static func definition(
        in registry: TypeRegistry<TypeDefinition.TypeId>
    ) -> FrameTypeDefinition
    
    static func validate(
        runtime: any Runtime,
        registry: any ThreadSynced<TypeRegistry<TypeDefinition.TypeId>>
    ) -> Result<Void, FrameTypeError>
}

public extension IdentifiableFrameType {
    @inlinable
    static func validate(runtime: any Runtime) -> Result<Void, FrameTypeError>
    {
        validate(runtime: runtime, registry: Data.typeRegistry)
    }
    
    @inlinable
    static func validate(
        runtime: any Runtime,
        registry: any ThreadSynced<TypeRegistry<TypeDefinition.TypeId>>
    ) -> Result<Void, FrameTypeError> {
        registry.sync{definition(in: $0)}.validate(type: Self.self, runtime: runtime)
    }
}

public extension FrameTypeDefinition {
    func validate(type: any IdentifiableFrameType.Type,
                  runtime: any Runtime) -> Result<Void, FrameTypeError>
    {
        switch self {
        case .call(fields: let fields):
            guard let info = runtime.resolve(callParams: type.name, pallet: type.frame) else {
                return .failure(.typeInfoNotFound(for: type, .get()))
            }
            return validate(fields: fields,
                            ifields: info.map{($0.name, *$0.type)},
                            type: type, runtime: runtime)
        case .event(fields: let fields):
            guard let info = runtime.resolve(eventParams: type.name, pallet: type.frame) else {
                return .failure(.typeInfoNotFound(for: type, .get()))
            }
            return validate(fields: fields,
                            ifields: info.map{($0.name, *$0.type)},
                            type: type, runtime: runtime)
        case .runtimeCall(params: let params, return: let rtype):
            guard let info = runtime.resolve(runtimeCall: type.name, api: type.frame) else {
                return .failure(.typeInfoNotFound(for: type, .get()))
            }
            return validate(fields: params, ifields: info.params,
                            type: type, runtime: runtime).flatMap {
                return rtype.validate(for: type.errorTypeName,
                                      type: info.result).mapError {
                    .childError(for: type, index: -1, error: $0, .get())
                }
            }
        case .constant(type: let vtype):
            guard let info = runtime.resolve(constant: type.name, pallet: type.frame) else {
                return .failure(.typeInfoNotFound(for: type, .get()))
            }
            return vtype.validate(for: type.errorTypeName,
                                  type: info.type).mapError {
                .childError(for: type, index: -1, error: $0, .get())
            }
        case .storage(keys: let path, value: let vtype):
            guard let info = runtime.resolve(storage: type.name, pallet: type.frame) else {
                return .failure(.typeInfoNotFound(for: type, .get()))
            }
            guard path.count == info.keys.count else {
                return .failure(.wrongFieldsCount(for: type, expected: path.count,
                                                  got: info.keys.count, .get()))
            }
            return zip(path, info.keys).enumerated().voidErrorMap { index, zip in
                let (pkey, ikey) = zip
                guard pkey.hasher == ikey.hasher else {
                    return .failure(.paramMismatch(for: type, index: index,
                                                   expected: pkey.hasher.description,
                                                   got: ikey.hasher.description, .get()))
                }
                return pkey.type.validate(for: type.errorTypeName,
                                          type: ikey.type)
                    .mapError { .childError(for: type, index: index, error: $0, .get()) }
            }.flatMap {
                vtype.validate(for: type.errorTypeName,
                               type: info.value).mapError {
                    .childError(for: type, index: -1, error: $0, .get())
                }
            }
        }
    }
    
    func validate(fields: [TypeDefinition.Field],
                  ifields: [(name: String?, type: TypeDefinition)],
                  type: any IdentifiableFrameType.Type,
                  runtime: any Runtime) -> Result<Void, FrameTypeError>
    {
        guard fields.count == ifields.count else {
            return .failure(.wrongFieldsCount(for: type, expected: fields.count,
                                              got: ifields.count, .get()))
        }
        return zip(fields, ifields).enumerated().voidErrorMap { index, zip in
            let (field, info) = zip
            return field.type.validate(for: type.errorTypeName,
                                       type: info.type).mapError {
                .childError(for: type, index: index, error: $0, .get())
            }
        }
    }
}

public extension FrameTypeError { // FrameType
    @inlinable
    static func typeInfoNotFound(for type: FrameType.Type,
                                 _ info: ErrorMethodInfo) -> Self
    {
        .typeInfoNotFound(for: type.errorTypeName, info)
    }
    
    @inlinable
    static func typeInfoNotFound(for type: FrameType.Type,
                                 index: UInt8, frame: UInt8,
                                 _ info: ErrorMethodInfo) -> Self
    {
        .typeInfoNotFound(for: type.errorTypeName,
                          index: index, frame: frame, info)
    }
    
    @inlinable
    static func foundWrongType(for type: FrameType.Type,
                               name: String, frame: String,
                               _ info: ErrorMethodInfo) -> Self
    {
        .foundWrongType(for: type.errorTypeName,
                        found: (name, frame), info)
    }
    
    @inlinable
    static func wrongType(for type: FrameType.Type,
                          got: String, reason: String,
                          _ info: ErrorMethodInfo) -> Self
    {
        .wrongType(for: type.errorTypeName, got: got,
                   reason: reason, info)
    }
    
    @inlinable
    static func wrongFieldsCount(for type: FrameType.Type,
                                 expected: Int, got: Int,
                                 _ info: ErrorMethodInfo) -> Self {
        .wrongFieldsCount(for: type.errorTypeName,
                          expected: expected, got: got, info)
    }
    
    @inlinable
    static func paramMismatch(for type: FrameType.Type, index: Int,
                              expected: Any, got: Any,
                              _ info: ErrorMethodInfo) -> Self {
        .paramMismatch(for: type.errorTypeName,
                       index: index,
                       expected: String(describing: expected),
                       got: String(describing: got), info)
    }
    
    @inlinable
    static func valueNotFound(for type: FrameType.Type, key: String,
                              _ info: ErrorMethodInfo) -> Self {
        .valueNotFound(for: type.errorTypeName,
                       key: key, info)
    }
    
    @inlinable
    static func childError(for type: FrameType.Type,
                           index: Int, error: TypeError,
                           _ info: ErrorMethodInfo) -> Self {
        .childError(for: type.errorTypeName,
                    index: index, error: error, info)
    }
}
