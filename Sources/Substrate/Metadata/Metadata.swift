//
//  Metadata.swift
//  
//
//  Created by Yehor Popovych on 12/29/20.
//

import Foundation
import ScaleCodec
import SubstratePrimitives

public class Metadata {
    public let registry: TypeRegistryProtocol
    
    public let modulesByName: Dictionary<String, MetadataModuleInfo>
    public let modulesByIndex: Dictionary<UInt8, MetadataModuleInfo>
    public let signedExtensions: [Any]
    
    public init(runtime: RuntimeMetadata, registry: TypeRegistryProtocol) throws {
        self.registry = registry
        let modules = try runtime.modules.map { try ($0.name, $0.index, MetadataModuleInfo(runtime: $0)) }
        let modulesByName = modules.map { ($0, $2) }
        let modulesByIndex = modules.map { ($1, $2) }
        self.modulesByName = Dictionary(uniqueKeysWithValues: modulesByName)
        self.modulesByIndex = Dictionary(uniqueKeysWithValues: modulesByIndex)
        signedExtensions = runtime.extrinsic.signedExtensions
    }
}

extension Metadata: MetadataProtocol {
    public func decode(callFrom decoder: ScaleDecoder) throws -> AnyCall {
        fatalError("Not implemented")
    }
    
    public func decode(eventFrom decoder: ScaleDecoder) throws -> AnyEvent {
        fatalError("Not implemented")
    }
    
    // StorageKey
    public func prefix<K: AnyStorageKey>(for key: K) throws -> Data {
        guard let module = modulesByName[key.module] else {
            throw MetadataError.moduleNotFound(name: key.module)
        }
        guard let storage = module.storage[key.field] else {
            throw MetadataError.storageItemNotFound(prefix: key.module, item: key.field)
        }
        return storage.prefixHash()
    }
    
    public func key<K: AnyStorageKey>(for key: K) throws -> Data {
        guard let module = modulesByName[key.module] else {
            throw MetadataError.moduleNotFound(name: key.module)
        }
        guard let storage = module.storage[key.field] else {
            throw MetadataError.storageItemNotFound(prefix: key.module, item: key.field)
        }
        return try storage.key(path: key.path, meta: self)
    }

    // Call
    public func encode<T: AnyCall>(call: T, in encoder: ScaleEncoder) throws {
        fatalError("Not implemented")
    }
    public func decode(call index: Int, module: Int, from decoder: ScaleDecoder) throws -> AnyCall {
        fatalError("Not implemented")
    }
    public func find(call: Int, module: Int) -> (module: String, function: String)? {
        fatalError("Not implemented")
    }

    // Event
    public func decode(event index: Int, module: Int, from decoder: ScaleDecoder) throws -> AnyEvent {
        fatalError("Not implemented")
    }
    public func find(event: Int, module: Int) -> (module: String, event: String)? {
        fatalError("Not implemented")
    }

    // Generic Values
    public func encode(
        value: ScaleDynamicEncodable, type: DType,
        in encoder: ScaleEncoder
    ) throws {
        switch type {
        case .null: return
        case .optional(element: let t): try _encodeOptional(type: t, val: value, encoder: encoder)
        case .plain(name: _): try value.encode(in: encoder, meta: self)
        case .tuple(elements: let types): try _encodeTuple(types: types, val: value, encoder: encoder)
        case .fixed(type: let t, count: let count):
            try _encodeFixed(type: t, val: value, count: count, encoder: encoder)
        case .collection(name: _, element: let t):
            try _encodeCollection(type: t, val: value, encoder: encoder)
        case .map(name: _, key: let kt, value: let vt):
            try _encodeMap(kt: kt, vt: vt, val: value, encoder: encoder)
        case .result: throw MetadataError.encodingNotSupported(for: type)
        }
    }

    public func decode(
        type: DType, from decoder: ScaleDecoder
    ) throws -> DValue {
        if case .null = type { return .null }
        do {
            let val = try registry.decodeValue(type: type, from: decoder, with: self)
            return .native(type: type, value: val)
        } catch TypeRegistryError.typeNotFound(_) {
            switch type {
            case .optional(element: let et):
                return try _decodeOptional(type: et, decoder: decoder)
            case .result(success: let st, error: let et):
                return try _decodeResult(type: st, etype: et, decoder: decoder)
            case .tuple(elements: let types):
                return try _decodeTuple(types: types, decoder: decoder)
            case .fixed(type: let type, count: let count):
                return try _decodeTuple(types: Array(repeating: type, count: count), decoder: decoder)
            case .collection(name: _, element: let t):
                return try _decodeCollection(type: t, decoder: decoder)
            case .map(name: _, key: let kt, value: let vt):
                return try _decodeMap(kt: kt, vt: vt, decoder: decoder)
            default: throw MetadataError.typeNotFound(type)
            }
        }
    }
}

private extension Metadata {
    func _encodeFixed(type: DType, val: ScaleDynamicEncodable, count: Int, encoder: ScaleEncoder) throws {
        guard let array = val as? NSArray else {
            throw MetadataError.expectedCollection(found: val)
        }
        guard array.count == count else {
            throw MetadataError.wrongElementCount(in: val, expected: count)
        }
        for v in array {
            try encode(value: v as! ScaleDynamicEncodable, type: type, in: encoder)
        }
    }
    
    func _encodeMap(kt: DType, vt: DType, val: ScaleDynamicEncodable, encoder: ScaleEncoder) throws {
        guard let map = val as? NSDictionary else {
            throw MetadataError.expectedMap(found: val)
        }
        let tuples = Array(map)
        let dictionary = Dictionary(
            uniqueKeysWithValues: tuples.enumerated().map { ($0.0, $0.1.value as! ScaleDynamicEncodable) }
        )
        try dictionary.encode(
            in: encoder,
            lwriter: { idx, encoder in
                let key = tuples[idx].key as! ScaleDynamicEncodable
                try self.encode(value: key, type: kt, in: encoder)
            },
            rwriter: { val, encoder in try self.encode(value: val, type: vt, in: encoder)}
        )
    }
    
    func _encodeCollection(type: DType, val: ScaleDynamicEncodable, encoder: ScaleEncoder) throws {
        guard let array = val as? NSArray else {
            throw MetadataError.expectedCollection(found: val)
        }
        try array.map { $0 as! ScaleDynamicEncodable }.encode(in: encoder) { val, encoder in
            try self.encode(value: val, type: type, in: encoder)
        }
    }
    
    func _encodeOptional(type: DType, val: ScaleDynamicEncodable, encoder: ScaleEncoder) throws {
        let optional: Optional<DNull> = val is DNull ? .none : .some(DNull())
        try optional.encode(in: encoder) { _, encoder in
            try self.encode(value: val, type: type, in: encoder)
        }
    }
    
    func _encodeTuple(types: [DType], val: ScaleDynamicEncodable, encoder: ScaleEncoder) throws {
        guard let array = val as? NSArray else {
            throw MetadataError.expectedCollection(found: val)
        }
        guard array.count == types.count else {
            throw MetadataError.wrongElementCount(in: val, expected: types.count)
        }
        for (t, v) in zip(types, array) {
            try encode(value: v as! ScaleDynamicEncodable, type: t, in: encoder)
        }
    }
    
    func _decodeOptional(type: DType, decoder: ScaleDecoder) throws -> DValue {
        let val = try Optional<DValue>(from: decoder) { decoder in
            try self.decode(type: type, from: decoder)
        }
        return val ?? .null
    }
    
    func _decodeResult(type: DType, etype: DType, decoder: ScaleDecoder) throws -> DValue {
        let val = try Result<DValue, DValue>(
            from: decoder,
            lreader: { try self.decode(type: type, from: $0) },
            rreader: { try self.decode(type: etype, from: $0) }
        )
        return .result(res: val)
    }
    
    func _decodeTuple(types: [DType], decoder: ScaleDecoder) throws -> DValue {
        let values = try types.map { type in
            try self.decode(type: type, from: decoder)
        }
        return .collection(values: values)
    }
    
    func _decodeMap(kt: DType, vt: DType, decoder: ScaleDecoder) throws -> DValue {
        var keys = Dictionary<Int, DValue>()
        var index = 0
        let values = try Dictionary<Int, DValue>(
            from: decoder,
            lreader: { decoder in
                index += 1
                let key = try self.decode(type: kt, from: decoder)
                keys[index] = key
                return index
            },
            rreader: { try self.decode(type: vt, from: $0) })
        return .map(values: values.map { (k, v) in (keys[k]!, v) })
    }
    
    func _decodeCollection(type: DType, decoder: ScaleDecoder) throws -> DValue {
        let values = try Array<DValue>(from: decoder) { decoder in
            try self.decode(type: type, from: decoder)
        }
        return .collection(values: values)
    }
}
