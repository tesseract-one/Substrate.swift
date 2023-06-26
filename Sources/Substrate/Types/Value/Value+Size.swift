//
//  Value+Size.swift
//  
//
//  Created by Yehor Popovych on 22/06/2023.
//

import Foundation
import ScaleCodec


public extension Value {
    static func calculateSize<D: SkippableDecoder>(
        in decoder: inout D, for id: RuntimeTypeId, runtime: any Runtime
    ) throws -> Int {
        guard let typeInfo = runtime.resolve(type: id) else {
            throw DecodingError.typeNotFound(id)
        }
        switch typeInfo.definition {
        case .primitive(is: let pType): return try _primitiveSize(in: &decoder, prim: pType)
        case .compact(of: _): return try _compactSize(in: &decoder)
            //        case .composite(fields: let fields):
            //            self = try Self._decodeComposite(from: decoder, type: type, fields: fields, runtime: runtime)
            //        case .sequence(of: let vType):
            //            self = try Self._decodeSequence(from: decoder, type: type, valueType: vType, runtime: runtime)
            //        case .variant(variants: let vars):
            //            self = try Self._decodeVariant(from: decoder, type: type, variants: vars, runtime: runtime)
            //        case .array(count: let count, of: let vType):
            //            self = try Self._decodeArray(
            //                from: decoder, type: type, valueType: vType, count: count, runtime: runtime
            //            )
            //        case .tuple(components: let fields):
            //            self = try Self._decodeTuple(from: decoder, type: type, fields: fields, runtime: runtime)
            //        case .primitive(is: let pType):
            //            self = try Self._decodePrimitive(from: decoder, type: type, prim: pType, runtime: runtime)
            //        case .compact(of: let cType):
            //            self = try Self._decodeCompact(from: decoder, type: type, of: cType, runtime: runtime)
            //        case .bitsequence(store: let store, order: let order):
            //            self = try Self._decodeBitSequence(
            //                from: decoder, type: type, store: store, order: order, runtime: runtime
            //            )
        default: fatalError()
        }
    }
}

private extension Value {
    static func _primitiveSize<D: SkippableDecoder>(
        in decoder: inout D, prim: RuntimeTypePrimitive
    ) throws -> Int {
        switch prim {
        case .bool: return try Bool.calculateSize(in: &decoder)
        case .u8: return try UInt8.calculateSize(in: &decoder)
        case .i8: return try Int8.calculateSize(in: &decoder)
        case .u16: return try UInt16.calculateSize(in: &decoder)
        case .i16: return try UInt16.calculateSize(in: &decoder)
        case .u32: return try UInt32.calculateSize(in: &decoder)
        case .i32: return try Int32.calculateSize(in: &decoder)
        case .char: return try Character.calculateSize(in: &decoder)
        case .u64: return try UInt64.calculateSize(in: &decoder)
        case .i64: return try Int64.calculateSize(in: &decoder)
        case .u128: return try UInt128.calculateSize(in: &decoder)
        case .i128: return try Int128.calculateSize(in: &decoder)
        case .u256: return try UInt256.calculateSize(in: &decoder)
        case .i256: return try Int256.calculateSize(in: &decoder)
        case .str: return try String.calculateSize(in: &decoder)
        }
    }
    
    static func _compactSize<D: SkippableDecoder>(in decoder: inout D) throws -> Int {
        return try Compact<UInt256>.calculateSize(in: &decoder)
    }
    
    static func _bitSequenceSize<D: SkippableDecoder>(
        from decoder: inout D, type: RuntimeTypeId,
        store: RuntimeTypeId, order: RuntimeTypeId, runtime: Runtime
    ) throws -> Int {
        let format = try BitSequence.Format(store: store, order: order, runtime: runtime)
        let cCount = try Compact<UInt32>.calculateSizeNoSkip(in: &decoder)
        let bitCount = try decoder.decode(UInt32.self, .compact)
        var count = bitCount.isMultiple(of: format.store.bits)
            ? Int(bitCount / 8)
            : Int((bitCount / format.store.bits)) + 1
        switch format.store {
        case .u8: break
        case .u16: count *= 2
        case .u32: count *= 4
        case .u64: count *= 8
        }
        try decoder.skip(count: count)
        return count + cCount
    }
}
