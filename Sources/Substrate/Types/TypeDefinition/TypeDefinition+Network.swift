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
                return .success(.n(param.name))
            }
            return from(type: type, types: types, registry: registry).map {
                .t(param.name, $0)
            }
        }.flatMap { parameters in
            registry.def(id: info.id) {
                from(definition: info.type.definition, types: types, registry: registry)
                    .map { .def($0).info(name: name, parameters: parameters,
                                         docs: info.type.docs) }
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
            }.map { $0.map { .v($0) } }.map { .composite(fields: $0) }
        case .composite(fields: let fields):
            if fields.count == 0 { return .success(.void) }
            return fields.resultMap { field in
                from(type: field.type, types: types, registry: registry).map {
                    .mkv(field.name, $0, typeName: field.typeName,
                         docs: field.docs.count > 0 ? field.docs : nil)
                }
            }.map { .composite(fields: $0) }
        case .variant(variants: let vars):
            return vars.resultMap { vart in
                vart.fields.resultMap { field in
                    from(type: field.type, types: types, registry: registry).map {
                        .mkv(field.name, $0, typeName: field.typeName,
                             docs: field.docs.count > 0 ? field.docs : nil)
                    }
                }.map { Variant(vart.index, vart.name, $0,
                                vart.docs.count > 0 ? vart.docs : nil) }
            }.map { .variant(variants: $0) }
        }
    }
}

public extension NetworkType.Info {
    @inlinable
    static func from<D: AnyTypeDefinition>(definition: D,
                                           types: inout [NetworkType.Id: NetworkType]) -> Self
    {
        var reversed = [ObjectIdentifier: NetworkType.Id]()
        return from(definition: definition, types: &types, reversed: &reversed)
    }
    
    static func from<D: AnyTypeDefinition>(definition: D,
                                           types: inout [NetworkType.Id: NetworkType],
                                           reversed: inout [ObjectIdentifier: NetworkType.Id]) -> Self
    {
        var bitSeq = BitSeqInfo()
        var next = UInt32(types.count)
        let id = from(definition: definition, types: &types,
                      bitSeq: &bitSeq, reversed: &reversed, next: &next)
        return id.i(types[id]!)
    }
    
    private static func from<D: AnyTypeDefinition>(
        definition: D,
        types: inout [NetworkType.Id: NetworkType],
        bitSeq: inout BitSeqInfo,
        reversed: inout [ObjectIdentifier: NetworkType.Id],
        next: inout UInt32
    ) -> NetworkType.Id {
        if let id = reversed[definition.objectId] { return id }
        let id = NetworkType.Id(id: next); next += 1
        reversed[definition.objectId] = id
        let path = definition.name.components(separatedBy: ".")
        let docs = definition.docs ?? []
        let parameters = definition.parameters?.map { param in
            NetworkType.Parameter(name: param.name, type: param.type.map {
                from(definition: $0, types: &types,
                     bitSeq: &bitSeq, reversed: &reversed, next: &next)
            })
        } ?? []
        switch definition.definition {
        case .primitive(is: let prim):
            types[id] = .init(path: path, parameters: parameters,
                              definition: .primitive(is: prim), docs: docs)
            bitSeq.primitive(name: definition.name, id: id, prim: prim)
        case .void:
            types[id] = .init(path: path, parameters: parameters,
                              definition: .composite(fields: []),
                              docs: docs)
        case .sequence(of: let child):
            let childId = from(definition: child, types: &types,
                               bitSeq: &bitSeq, reversed: &reversed,
                               next: &next)
            types[id] = .init(path: path, parameters: parameters,
                              definition: .sequence(of: childId), docs: docs)
        case .compact(of: let child):
            let childId = from(definition: child, types: &types,
                               bitSeq: &bitSeq, reversed: &reversed,
                               next: &next)
            types[id] = .init(path: path, parameters: parameters,
                              definition: .compact(of: childId), docs: docs)
        case .array(count: let count, of: let child):
            let childId = from(definition: child, types: &types,
                               bitSeq: &bitSeq, reversed: &reversed,
                               next: &next)
            types[id] = .init(path: path, parameters: parameters,
                              definition: .array(count: count, of: childId), docs: docs)
        case .composite(fields: let fields):
            let mapped = fields.map { field in
                let id = from(definition: field.type, types: &types,
                              bitSeq: &bitSeq, reversed: &reversed,
                              next: &next)
                return NetworkType.Field(name: field.name, type: id,
                                         typeName: field.typeName,
                                         docs: field.docs ?? [])
            }
            types[id] = .init(path: path, parameters: parameters,
                              definition: .composite(fields: mapped), docs: docs)
        case .variant(variants: let vars):
            let mapped = vars.map { vart in
                let fields = vart.fields.map { field in
                    let id = from(definition: field.type, types: &types,
                                  bitSeq: &bitSeq, reversed: &reversed,
                                  next: &next)
                    return NetworkType.Field(name: field.name, type: id,
                                             typeName: field.typeName,
                                             docs: field.docs ?? [])
                }
                return NetworkType.Variant(name: vart.name, fields: fields,
                                           index: vart.index, docs: vart.docs ?? [])
            }
            types[id] = .init(path: path, parameters: parameters,
                              definition: .variant(variants: mapped), docs: docs)
        case .bitsequence(format: let format):
            let order = bitSeq.order(format.order, types: &types, next: &next)
            let store = bitSeq.store(format.store, types: &types, next: &next)
            types[id] = .init(path: path, parameters: parameters,
                              definition: .bitsequence(store: store, order: order),
                              docs: docs)
        }
        return id
    }
    
    private struct BitSeqInfo {
        var u8: NetworkType.Id? = nil
        var u16: NetworkType.Id? = nil
        var u32: NetworkType.Id? = nil
        var u64: NetworkType.Id? = nil
        var msb0: NetworkType.Id? = nil
        var lsb0: NetworkType.Id? = nil
        
        mutating func primitive(name: String, id: NetworkType.Id,
                                prim: NetworkType.Primitive)
        {
            switch prim {
            case .u8:
                if u8 == nil && (name == "" || name == "UInt8") { u8 = id }
            case .u16:
                if u16 == nil && (name == "" || name == "UInt16") { u16 = id }
            case .u32:
                if u32 == nil && (name == "" || name == "UInt32") { u32 = id }
            case .u64:
                if u64 == nil && (name == "" || name == "UInt64") { u64 = id }
            default: return
            }
        }
        
        mutating func store(_ store: BitSequence.Format.Store,
                            types: inout [NetworkType.Id: NetworkType],
                            next: inout UInt32) -> NetworkType.Id
        {
            switch store {
            case .u8:
                if let u8 = u8 { return u8 }
                u8 = NetworkType.Id(id: next); next += 1
                types[u8!] = store.type
                return u8!
            case .u16:
                if let u16 = u16 { return u16 }
                u16 = NetworkType.Id(id: next); next += 1
                types[u16!] = store.type
                return u16!
            case .u32:
                if let u32 = u32 { return u32 }
                u32 = NetworkType.Id(id: next); next += 1
                types[u32!] = store.type
                return u32!
            case .u64:
                if let u64 = u64 { return u64 }
                u64 = NetworkType.Id(id: next); next += 1
                types[u64!] = store.type
                return u64!
            }
        }
        
        mutating func order(_ order: BitSequence.Format.Order,
                            types: inout [NetworkType.Id: NetworkType],
                            next: inout UInt32) -> NetworkType.Id
        {
            switch order {
            case .lsb0:
                if let lsb0 = lsb0 { return lsb0 }
                lsb0 = NetworkType.Id(id: next); next += 1
                types[lsb0!] = order.type
                return lsb0!
            case .msb0:
                if let msb0 = msb0 { return msb0 }
                msb0 = NetworkType.Id(id: next); next += 1
                types[msb0!] = order.type
                return msb0!
            }
        }
    }
}
