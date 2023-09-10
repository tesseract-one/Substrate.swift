//
//  TypeDefinition+Network.swift
//  
//
//  Created by Yehor Popovych on 08/09/2023.
//

import Foundation

public extension TypeDefinition {
    @inlinable
    static func from(
        type id: NetworkType.Id,
        types: [NetworkType.Id: NetworkType],
        registry: TypeRegistry<NetworkType.Id>
    ) -> Result<TypeDefinition, MetadataError> {
        guard let type = types[id] else {
            return .failure(.typeNotFound(id: id, info: .get()))
        }
        return from(type: id.i(type), types: types, registry: registry)
    }
    
    static func from(
        type info: NetworkType.Info,
        types: [NetworkType.Id: NetworkType],
        registry: TypeRegistry<NetworkType.Id>
    ) -> Result<TypeDefinition, MetadataError> {
        if let def = registry[info.id] { return .success(def) }
        let name = info.type.name ?? ""
        return info.type.parameters.resultMap { param in
            guard let type = param.type else {
                return .success(Parameter(name: param.name, type: nil))
            }
            return from(type: type, types: types, registry: registry).map {
                Parameter(name: param.name, type: $0)
            }
        }.flatMap { parameters in
            registry.def(id: info.id) {
                from(definition: info.type.definition, types: types, registry: registry)
                    .map { .def($0).info(name: name, parameters: parameters) }
            }
        }
    }
    
    private static func from(
        definition: NetworkType.Definition,
        types: [NetworkType.Id: NetworkType],
        registry: TypeRegistry<NetworkType.Id>
    ) -> Result<TypeDefinition.Def, MetadataError> {
        switch definition {
        case .primitive(is: let prim):
            return .success(.primitive(is: prim))
        case .sequence(of: let id):
            return from(type: id, types: types, registry: registry).map { def in
                .sequence(of: def)
            }
        case .compact(of: let id):
            return from(type: id, types: types, registry: registry).map { def in
                .compact(of: def)
            }
        case .array(count: let count, of: let id):
            return from(type: id, types: types, registry: registry).map { def in
                .array(count: count, of: def)
            }
        case .bitsequence(store: let sid, order: let oid):
            return BitSequence.Format.from(store: sid, order: oid,
                                           types: types).map {
                .bitsequence(format: $0)
            }
        case .tuple(components: let ids):
            if ids.count == 0 { return .success(.void) }
            return ids.resultMap { id in
                from(type: id, types: types, registry: registry)
            }.map { $0.map { Field(nil, $0) } }.map { .composite(fields: $0) }
        case .composite(fields: let fields):
            if fields.count == 0 { return .success(.void) }
            return fields.resultMap { field in
                from(type: field.type, types: types, registry: registry).map {
                    Field(field.name, $0)
                }
            }.map { .composite(fields: $0) }
        case .variant(variants: let vars):
            return vars.resultMap { vart in
                vart.fields.resultMap { field in
                    from(type: field.type, types: types, registry: registry).map {
                        Field(field.name, $0)
                    }
                }.map { Variant(vart.index, vart.name, $0) }
            }.map { .variant(variants: $0) }
        }
    }
}
