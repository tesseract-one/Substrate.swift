//
//  TypeRegistry+Encode.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import ScaleCodec
import BigInt

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
        case .result(success: let vt, error: let et):
            try _encodeResult(vtype: vt, etype: et, val: value, encoder: encoder)
        case .doNotConstruct: throw TypeRegistryError.encodingNotSupported(for: type)
        }
    }
    
    func _encode(dynamic: DValue, type: DType, in encoder: ScaleEncoder) throws {
        try _encode(value: dynamic.dynamicEncodable, type: type, in: encoder)
    }
    
    private func _encodeCompact(value: ScaleDynamicEncodable, encoder: ScaleEncoder) throws {
        guard let val = value as? CompactConvertible else {
            throw TypeRegistryError.encodingValueIsNotCompactCodable(value: value)
        }
        
        try _typeEncodingError(value) {
            let compact: SCompact<BigUInt> = try val.compact()
            try encoder.encode(compact)
        }
    }
    
    private func _encodeFixed(type: DType, val: ScaleDynamicEncodable, count: Int, encoder: ScaleEncoder) throws {
        guard let enc = val as? ScaleDynamicEncodableCollectionConvertible else {
            throw TypeRegistryError.encodingExpectedCollection(found: val)
        }
        let array = enc.encodableCollection.array
        guard array.count == count else {
            throw TypeRegistryError.encodingWrongElementCount(in: val, expected: count)
        }
        for v in array {
            try _encode(value: v, type: type, in: encoder)
        }
    }

    private func _encodeMap(kt: DType, vt: DType, val: ScaleDynamicEncodable, encoder: ScaleEncoder) throws {
        guard let enc = val as? ScaleDynamicEncodableMapConvertible else {
            throw TypeRegistryError.encodingExpectedMap(found: val)
        }
        let tuples = enc.encodableMap.map
        let dictionary = Dictionary(
            uniqueKeysWithValues: tuples.enumerated().map { ($0.0, $0.1.value) }
        )
        try dictionary.encode(
            in: encoder,
            lwriter: { idx, encoder in
                let key = tuples[idx].key
                try self._encode(value: key, type: kt, in: encoder)
            },
            rwriter: { val, encoder in try self._encode(value: val, type: vt, in: encoder)}
        )
    }
    
    private func _encodeResult(
        vtype: DType, etype: DType, val: ScaleDynamicEncodable, encoder: ScaleEncoder
    ) throws {
        guard let enc = val as? ScaleDynamicEncodableEitherConvertible else {
            throw TypeRegistryError.encodingExpectedResult(found: val)
        }
        let result: Result<DNull, DNull>
        let value: ScaleDynamicEncodable
        switch enc.encodableEither {
        case .left(val: let val):
            value = val
            result = .success(DNull())
        case .right(val: let err):
            value = err
            result = .failure(DNull())
        }
        try result.encode(
            in: encoder,
            lwriter: { _, encoder in
                try self._encode(value: value, type: vtype, in: encoder)
            },
            rwriter: { _, encoder in
                try self._encode(value: value, type: etype, in: encoder)
            }
        )
    }

    private func _encodeCollection(type: DType, val: ScaleDynamicEncodable, encoder: ScaleEncoder) throws {
        guard let enc = val as? ScaleDynamicEncodableCollectionConvertible else {
            throw TypeRegistryError.encodingExpectedCollection(found: val)
        }
        let array = enc.encodableCollection.array
        try array.encode(in: encoder) { val, encoder in
            try self._encode(value: val, type: type, in: encoder)
        }
    }

    private func _encodeOptional(type: DType, val: ScaleDynamicEncodable, encoder: ScaleEncoder) throws {
        if let enc = val as? ScaleDynamicEncodableOptionalConvertible { // someone passed real optional or DNull
            try enc.encodableOptional.optional.encode(in: encoder) { val2, encoder in
                try self.encode(value: val2, type: type, in: encoder)
            }
        } else { // Not null. Some value
            try Optional(DNull()).encode(in: encoder) { _, encoder in
                try self._encode(value: val, type: type, in: encoder)
            }
        }
    }

    private func _encodeTuple(types: [DType], val: ScaleDynamicEncodable, encoder: ScaleEncoder) throws {
        guard let enc = val as? ScaleDynamicEncodableCollectionConvertible else {
            throw TypeRegistryError.encodingExpectedCollection(found: val)
        }
        let array = enc.encodableCollection.array
        guard array.count == types.count else {
            throw TypeRegistryError.encodingWrongElementCount(in: val, expected: types.count)
        }
        for (t, v) in zip(types, array) {
            try _encode(value: v, type: t, in: encoder)
        }
    }
}
