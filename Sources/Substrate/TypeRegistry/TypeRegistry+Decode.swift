//
//  TypeRegistry+Decode.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import ScaleCodec

extension TypeRegistry {
    func _decodeEventHeader(from decoder: ScaleDecoder) throws -> (module: String, event: MetadataEventInfo) {
        let u8t = try type(of: UInt8.self)
        let moduleIndex = try _typeDecodingError(u8t) { try decoder.decode(UInt8.self) }
        let module = try _metaError { try self.meta.module(index: moduleIndex) }
        let eventIndex = try _typeDecodingError(u8t) { try decoder.decode(UInt8.self) }
        let event = try _metaError { try module.event(index: eventIndex) }
        return (module: module.name, event: event)
    }
    
    func _decodeCallHeader(from decoder: ScaleDecoder) throws -> (module: String, call: MetadataCallInfo) {
        let u8t = try type(of: UInt8.self)
        let moduleIndex = try _typeDecodingError(u8t) { try decoder.decode(UInt8.self) }
        let module = try _metaError { try self.meta.module(index: moduleIndex) }
        let callIndex = try _typeDecodingError(u8t) { try decoder.decode(UInt8.self) }
        let call = try _metaError { try module.call(index: callIndex) }
        return (module: module.name, call: call)
    }
    
    func _decodeStorageItemHeader(
        module: String, field: String, from decoder: ScaleDecoder
    ) throws -> MetadataStorageItemInfo {
        let mod = try _metaError { try self.meta.module(name: module) }
        let info = try _metaError { try mod.storageItem(name: field) }
        return try _storageKeyDecodingError(module: module, field: field) {
            let prefixLength = info.prefixHashLength()
            let parsedPrefix: Data = try decoder.decode(.fixed(UInt(prefixLength)))
            let prefix = info.prefixHash()
            guard parsedPrefix == prefix else {
                throw TypeRegistryError.storageItemDecodingBadPrefix(
                    module: module, field: field, prefix: parsedPrefix, expected: prefix
                )
            }
            return info
        }
    }
    
    func _decode(
        type: DType, from decoder: ScaleDecoder
    ) throws -> DValue {
        if case .null = type { return .null }
        do {
            let val = try decode(static: type, from: decoder)
            return .native(type: type, value: val)
        } catch TypeRegistryError.typeNotFound(_) {
            switch type {
            case .compact(type: _):
                return try _decodeCompact(type: type, decoder: decoder)
            case .optional(element: let et):
                return try _decodeOptional(type: et, decoder: decoder)
            case .result(success: let st, error: let et):
                return try _decodeResult(type: st, etype: et, decoder: decoder)
            case .tuple(elements: let types):
                return try _decodeTuple(types: types, decoder: decoder)
            case .fixed(type: let type, count: let count):
                return try _decodeFixed(type: type, size: count, decoder: decoder)
            case .collection(element: let t):
                return try _decodeCollection(type: t, decoder: decoder)
            case .map(key: let kt, value: let vt):
                return try _decodeMap(kt: kt, vt: vt, decoder: decoder)
            default: throw MetadataError.typeNotFound(type)
            }
        }
    }
    
    private func _decodeCompact(type: DType, decoder: ScaleDecoder) throws -> DValue {
        let value = try decoder.decode(SCompact<BigUInt>.self)
        return .native(type: type, value: value)
    }
    
    private func _decodeOptional(type: DType, decoder: ScaleDecoder) throws -> DValue {
        let val = try Optional<DValue>(from: decoder) { decoder in
            try self._decode(type: type, from: decoder)
        }
        return val ?? .null
    }

    private func _decodeResult(type: DType, etype: DType, decoder: ScaleDecoder) throws -> DValue {
        let val = try Result<DValue, DValue>(
            from: decoder,
            lreader: { try self._decode(type: type, from: $0) },
            rreader: { try self._decode(type: etype, from: $0) }
        )
        return .result(res: val)
    }

    private func _decodeTuple(types: [DType], decoder: ScaleDecoder) throws -> DValue {
        let values = try types.map { type in
            try self._decode(type: type, from: decoder)
        }
        return .collection(values: values)
    }
    
    private func _decodeFixed(type: DType, size: Int, decoder: ScaleDecoder) throws -> DValue {
        let values = try (0..<size).map { _ in try self._decode(type: type, from: decoder) }
        return .collection(values: values)
    }

    private func _decodeMap(kt: DType, vt: DType, decoder: ScaleDecoder) throws -> DValue {
        var keys = Dictionary<Int, DValue>()
        var index = 0
        let values = try Dictionary<Int, DValue>(
            from: decoder,
            lreader: { decoder in
                index += 1
                let key = try self._decode(type: kt, from: decoder)
                keys[index] = key
                return index
            },
            rreader: { try self._decode(type: vt, from: $0) })
        return .map(values: values.map { (k, v) in (keys[k]!, v) })
    }

    private func _decodeCollection(type: DType, decoder: ScaleDecoder) throws -> DValue {
        let values = try Array<DValue>(from: decoder) { decoder in
            try self._decode(type: type, from: decoder)
        }
        return .collection(values: values)
    }
}

