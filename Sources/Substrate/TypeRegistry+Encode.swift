//
//  TypeRegistry+Encode.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import ScaleCodec

extension TypeRegistry {
    func _encode(
        value: ScaleDynamicEncodable, type: DType,
        in encoder: ScaleEncoder
    ) throws {
        switch type {
        case .null: return
        case .compact(type: _): try _encodeCompact(value: value, encoder: encoder)
        case .optional(element: let t): try _encodeOptional(type: t, val: value, encoder: encoder)
        case .type(name: _):
            try _typeEncodingError(value) { try value.encode(in: encoder, registry: self) }
        case .tuple(elements: let types): try _encodeTuple(types: types, val: value, encoder: encoder)
        case .fixed(type: let t, count: let count):
            try _encodeFixed(type: t, val: value, count: count, encoder: encoder)
        case .collection(element: let t):
            try _encodeCollection(type: t, val: value, encoder: encoder)
        case .map(key: let kt, value: let vt):
            try _encodeMap(kt: kt, vt: vt, val: value, encoder: encoder)
        case .result: throw TypeRegistryError.encodingNotSupported(for: type)
        case .doNotConstruct: throw TypeRegistryError.encodingNotSupported(for: type)
        }
    }
    
    private func _encodeCompact(value: ScaleDynamicEncodable, encoder: ScaleEncoder) throws {
        guard let val = value as? CompactConvertible else {
            throw TypeRegistryError.encodingValueIsNotCompactCodable(value: value)
        }
        try _typeEncodingError(value) { try encoder.encode(val.compact) }
    }
    
    private func _encodeFixed(type: DType, val: ScaleDynamicEncodable, count: Int, encoder: ScaleEncoder) throws {
        guard let array = val as? NSArray else {
            throw TypeRegistryError.encodingExpectedCollection(found: val)
        }
        guard array.count == count else {
            throw TypeRegistryError.encodingWrongElementCount(in: val, expected: count)
        }
        for v in array {
            try _encode(value: v as! ScaleDynamicEncodable, type: type, in: encoder)
        }
    }

    private func _encodeMap(kt: DType, vt: DType, val: ScaleDynamicEncodable, encoder: ScaleEncoder) throws {
        guard let map = val as? NSDictionary else {
            throw TypeRegistryError.encodingExpectedMap(found: val)
        }
        let tuples = Array(map)
        let dictionary = Dictionary(
            uniqueKeysWithValues: tuples.enumerated().map { ($0.0, $0.1.value as! ScaleDynamicEncodable) }
        )
        try dictionary.encode(
            in: encoder,
            lwriter: { idx, encoder in
                let key = tuples[idx].key as! ScaleDynamicEncodable
                try self._encode(value: key, type: kt, in: encoder)
            },
            rwriter: { val, encoder in try self._encode(value: val, type: vt, in: encoder)}
        )
    }

    private func _encodeCollection(type: DType, val: ScaleDynamicEncodable, encoder: ScaleEncoder) throws {
        guard let array = val as? NSArray else {
            throw TypeRegistryError.encodingExpectedCollection(found: val)
        }
        try array.map { $0 as! ScaleDynamicEncodable }.encode(in: encoder) { val, encoder in
            try self._encode(value: val, type: type, in: encoder)
        }
    }

    private func _encodeOptional(type: DType, val: ScaleDynamicEncodable, encoder: ScaleEncoder) throws {
        let optional: Optional<DNull> = val is DNull ? .none : .some(DNull())
        try optional.encode(in: encoder) { _, encoder in
            try self._encode(value: val, type: type, in: encoder)
        }
    }

    private func _encodeTuple(types: [DType], val: ScaleDynamicEncodable, encoder: ScaleEncoder) throws {
        guard let array = val as? NSArray else {
            throw TypeRegistryError.encodingExpectedCollection(found: val)
        }
        guard array.count == types.count else {
            throw TypeRegistryError.encodingWrongElementCount(in: val, expected: types.count)
        }
        for (t, v) in zip(types, array) {
            try _encode(value: v as! ScaleDynamicEncodable, type: t, in: encoder)
        }
    }
}
