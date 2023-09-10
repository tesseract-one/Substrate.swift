//
//  TypeRegistry.swift
//  
//
//  Created by Yehor Popovych on 08/09/2023.
//

import Foundation
import ScaleCodec

public typealias NetworkTypeRegistry = TypeRegistry<NetworkType.Id>

public final class TypeRegistry<Id: Hashable>: Equatable, Hashable, CustomStringConvertible {
    // [ObjectIdentifier(TypeDef): Id]
    public typealias Reversed = [ObjectIdentifier: Id]
    
    public private(set) var types: [Id: TypeDefinition.Storage]
    
    @inlinable
    public var description: String { types.description }
    
    @inlinable
    public var definitions: [Id: TypeDefinition] { types.mapValues{$0.strong} }
    
    @inlinable
    public var reversed: Reversed {
        Dictionary(
            uniqueKeysWithValues: types.map { ($1.id, $0) }
        )
    }
    
    public init(types: [Id: TypeDefinition.Storage] = [:]) {
        self.types = types
    }
    
    public subscript(_ id: Id) -> TypeDefinition? { types[id]?.strong }
    
    @inlinable
    public func hash(into hasher: inout Swift.Hasher) {
        types.hash(into: &hasher)
    }
    
    @inlinable
    public static func == (lhs: TypeRegistry, rhs: TypeRegistry) -> Bool {
        lhs.types == rhs.types
    }
    
    private func add(id: Id, storage: TypeDefinition.Storage) {
        types[id] = storage
    }
}

public extension TypeRegistry where Id == NetworkType.Id {
    // MetadataError
    func get(_ id: Id, _ info: ErrorMethodInfo) throws -> TypeDefinition {
        guard let def = self[id] else {
            throw MetadataError.typeNotFound(id: id, info: info)
        }
        return def
    }
    
    func def(
        id: Id,
        _ ctr: () -> Result<(TypeDefinition.Builder), MetadataError>
    ) -> Result<TypeDefinition, MetadataError> {
        if let def = self[id] { return .success(def) }
        let storage = TypeDefinition.Storage(registry: self)
        add(id: id, storage: storage)
        return storage.initialize(ctr)
    }
    
    static func from(
        network: NetworkType.Registry
    ) -> Result<TypeRegistry<Id>, MetadataError> {
        let types = Dictionary<NetworkType.Id, NetworkType>(
            uniqueKeysWithValues: network.map { ($0.id, $0.type) }
        )
        let registry = TypeRegistry<Id>()
        return network.voidErrorMap { info in
            TypeDefinition.from(type: info.id, types: types, registry: registry).map{_ in}
        }.map { registry }
    }
}

public extension TypeRegistry where Id == TypeDefinition.TypeId {
    func def<T: IdentifiableTypeStatic>(_ type: T.Type) -> TypeDefinition {
        let id = TypeDefinition.TypeId(type: type, config: nil)
        if let def = self[id] { return def }
        let storage = TypeDefinition.Storage(registry: self)
        add(id: id, storage: storage)
        return try! storage.initialize { () -> Result<_, Never> in
            var bdr = type.definition(in: self)
            if bdr.params.name == nil {
                bdr = bdr.name("\(type)")
            }
            return .success(bdr)
        }.get()
    }
    
    func def<T>(
        _ type: T.Type, child: T.Type, config: T.TypeConfig,
        _ wrapped: (TypeRegistry<Id>, T.TypeConfig) -> TypeDefinition.Builder
    ) -> TypeDefinition
        where T: IdentifiableTypeCustomWrapperStatic
    {
        let sfId = TypeDefinition.TypeId(type: type, config: "\(child)\(config)")
        if let def = self[sfId] { return def }
        let chId = TypeDefinition.TypeId(type: child, config: config.description)
        var wdef = self[chId]
        if wdef == nil {
            let storage = TypeDefinition.Storage(registry: self)
            add(id: chId, storage: storage)
            wdef = try! storage.initialize { () -> Result<_, Never> in
                var bdr = wrapped(self, config)
                if bdr.params.name == nil {
                    bdr = bdr.name("\(child)\(config)")
                }
                return .success(bdr)
            }.get()
        }
        let storage = TypeDefinition.Storage(registry: self)
        add(id: sfId, storage: storage)
        return try! storage.initialize { () -> Result<_, Never> in
            var bdr = type.definition(in: self, config: config, wrapped: wdef!)
            if bdr.params.name == nil {
                bdr = bdr.name("\(type)\(config)")
            }
            return .success(bdr)
        }.get()
    }
    
    func def<T: IdentifiableWithConfigTypeStatic>(_ type: T.Type,
                                                  _ config: T.TypeConfig) -> TypeDefinition
    {
        let id = TypeDefinition.TypeId(type: type, config: config.description)
        if let def = self[id] { return def }
        let storage = TypeDefinition.Storage(registry: self)
        add(id: id, storage: storage)
        return try! storage.initialize { () -> Result<_, Never> in
            var bdr = type.definition(in: self, config)
            if bdr.params.name == nil {
                bdr = bdr.name("\(type)\(config)")
            }
            return .success(bdr)
        }.get()
    }
    
    func def<T: CompactCodable & IdentifiableTypeStatic>(compact type: T.Type) -> TypeDefinition {
        def(Compact<T>.self)
    }
}
