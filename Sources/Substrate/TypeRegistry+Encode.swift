//
//  TypeRegistry+Encode.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import ScaleCodec
import BigInt

private extension DValue {
    func encodable() -> ScaleDynamicEncodable {
        switch self {
        case .null: return DNull()
        case .native(type: _, value: let v): return v
        case .collection(values: let values):
            return (values.map { $0.encodable() }) as NSArray
        case .map(values: let values):
            return (values.map { (key: $0.key.encodable(), value: $0.value.encodable()) }) as NSArray
        case .result(res: _): return DNull() // Encoding isn't supported anyway.
        }
    }
}

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
    
    func _encodeCallHeader(call: AnyCall, in encoder: ScaleEncoder) throws {
        let module = try _metaError { try self.meta.module(name: call.module) }
        let info = try _metaError { try module.call(name: call.function) }
        try _callEncodingError(call) { try encoder.encode(module.index) }
        try _callEncodingError(call) { try encoder.encode(info.index) }
    }
    
    func _encodeDynamicCallParams(call: DynamicCall, in encoder: ScaleEncoder) throws {
        let module = try _metaError { try self.meta.module(name: call.module) }
        let info = try _metaError { try module.call(name: call.function) }
        let types = info.argumentsList.map { $0.1 }
        guard types.count == call.params.count else {
            throw TypeRegistryError.callEncodingWrongParametersCount(
                call: call, count: call.params.count, expected: types.count
            )
        }
        for (t, p) in zip(types, call.params) {
            try _encode(value: p.encodable(), type: t, in: encoder)
        }
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
        var tuples: Array<(key: ScaleDynamicEncodable, value: ScaleDynamicEncodable)>
        if let array = val as? NSArray {
            tuples = try array.map {
                guard let tuple = $0 as? (key: ScaleDynamicEncodable, value: ScaleDynamicEncodable) else {
                    throw TypeRegistryError.encodingExpectedMap(found: val)
                }
                return tuple
            }
        } else if let dict = val as? NSDictionary {
            tuples = try Array(dict).map {
                guard let tuple = $0 as? (key: ScaleDynamicEncodable, value: ScaleDynamicEncodable) else {
                    throw TypeRegistryError.encodingExpectedMap(found: val)
                }
                return tuple
            }
        } else {
            throw TypeRegistryError.encodingExpectedMap(found: val)
        }
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

    private func _encodeCollection(type: DType, val: ScaleDynamicEncodable, encoder: ScaleEncoder) throws {
        var array: Array<ScaleDynamicEncodable>
        if let arrEnc = val as? ScaleDynamicEncodableArrayMaybeConvertible { // STuple or NSArray
            guard let arr = arrEnc.encodableArray else {
                throw TypeRegistryError.encodingExpectedCollection(found: val)
            }
            array = arr
        } else if let nsarr = val as? NSArray { // array
            guard let arr = nsarr.encodableArray else {
                throw TypeRegistryError.encodingExpectedCollection(found: val)
            }
            array = arr
        } else {
            throw TypeRegistryError.encodingExpectedCollection(found: val)
        }
        try array.encode(in: encoder) { val, encoder in
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
        var array: Array<ScaleDynamicEncodable>
        if let arrEnc = val as? ScaleDynamicEncodableArrayMaybeConvertible { // STuple or NSArray
            guard let arr = arrEnc.encodableArray else {
                throw TypeRegistryError.encodingExpectedCollection(found: val)
            }
            array = arr
        } else if let nsarr = val as? NSArray { // array
            guard let arr = nsarr.encodableArray else {
                throw TypeRegistryError.encodingExpectedCollection(found: val)
            }
            array = arr
        } else {
            throw TypeRegistryError.encodingExpectedCollection(found: val)
        }
        guard array.count == types.count else {
            throw TypeRegistryError.encodingWrongElementCount(in: val, expected: types.count)
        }
        for (t, v) in zip(types, array) {
            try _encode(value: v, type: t, in: encoder)
        }
    }
}
