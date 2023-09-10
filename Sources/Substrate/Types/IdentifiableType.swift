//
//  IdentifiableType.swift
//  
//
//  Created by Yehor Popovych on 02/09/2023.
//

import Foundation

public protocol IdentifiableTypeStatic: ValidatableTypeStatic {
    static func definition(
        in registry: TypeRegistry<TypeDefinition.TypeId>
    ) -> TypeDefinition.Builder
    
    static func validate(
        type: TypeDefinition,
        registry: any ThreadSynced<TypeRegistry<TypeDefinition.TypeId>>
    ) -> Result<Void, TypeError>
    
    static var typeRegistry: Synced<TypeRegistry<TypeDefinition.TypeId>> { get }
}

public extension IdentifiableTypeStatic {
    @inlinable
    static var typeRegistry: Synced<TypeRegistry<TypeDefinition.TypeId>> {
        GLOBAL_STATIC_TYPE_REGISTRY
    }
}

public extension IdentifiableTypeStatic {
    @inlinable
    static func validate(type: TypeDefinition) -> Result<Void, TypeError>
    {
        validate(type: type, registry: typeRegistry)
    }
    
    @inlinable
    static func validate(
        type: TypeDefinition,
        registry: any ThreadSynced<TypeRegistry<TypeDefinition.TypeId>>
    ) -> Result<Void, TypeError> {
        registry.sync{$0.def(Self.self)}.validate(for: Self.self, type: type)
    }
}

public protocol IdentifiableWithConfigTypeStatic {
    associatedtype TypeConfig: CustomStringConvertible
    
    static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>,
                           _ config: TypeConfig) -> TypeDefinition.Builder
}

public protocol IdentifiableTypeCustomWrapperStatic {
    associatedtype TypeConfig: CustomStringConvertible
    
    static func definition(
        in registry: TypeRegistry<TypeDefinition.TypeId>,
        config: TypeConfig, wrapped: TypeDefinition
    ) -> TypeDefinition.Builder
}

public extension IdentifiableWithConfigTypeStatic where TypeConfig: Default {
    static func definition(
        in registry: TypeRegistry<TypeDefinition.TypeId>
    ) -> TypeDefinition.Builder {
        definition(in: registry, .default)
    }
}

public extension IdentifiableTypeCustomWrapperStatic where TypeConfig: Default {
    static func definition(
        in registry: TypeRegistry<TypeDefinition.TypeId>,
        wrapped: TypeDefinition
    ) -> TypeDefinition.Builder {
        definition(in: registry, config: .default, wrapped: wrapped)
    }
}

public enum IdentifiableCollectionTypeConfig: CustomStringConvertible, Default {
    case dynamic
    case fixed(UInt32)
    
    public var description: String {
        switch self {
        case .dynamic: return ""
        case .fixed(let count): return "[\(count)]"
        }
    }
    
    public static var `default`: IdentifiableCollectionTypeConfig = .dynamic
}

public typealias IdentifiableType = IdentifiableTypeStatic & ValidatableType

public let GLOBAL_STATIC_TYPE_REGISTRY = Synced(value: TypeRegistry<TypeDefinition.TypeId>())
