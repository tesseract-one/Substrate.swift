//
//  Value+Size.swift
//  
//
//  Created by Yehor Popovych on 22/06/2023.
//

import Foundation
import ScaleCodec


public extension Value {
    static func calculateSize(
        in decoder: ScaleCodec.Decoder, for id: NetworkType.Id, runtime: any Runtime
    ) throws -> Int {
        var skippable = decoder.skippable()
        return try calculateSize(in: &skippable, for: id, runtime: runtime)
    }
    
    static func calculateSize<D: SkippableDecoder>(
        in decoder: inout D, for id: NetworkType.Id, runtime: any Runtime
    ) throws -> Int {
        guard let typeInfo = runtime.resolve(type: id) else {
            throw DecodingError.typeNotFound(id)
        }
        switch typeInfo.definition {
        case .primitive(is: let pType): return try _primitiveSize(in: &decoder, prim: pType)
        case .compact(of: _): return try _compactSize(in: &decoder)
        case .bitsequence(store: let store, order: let order):
            return try _bitSequenceSize(from: &decoder, store: store, order: order, runtime: runtime)
        case .tuple(components: let fields):
            return try _tupleSize(from: &decoder, fields: fields, runtime: runtime)
        case .array(count: let count, of: let vType):
            return try _arraySize(from: &decoder, count: Int(count), type: vType, runtime: runtime)
        case .sequence(of: let vType):
            return try _sequenceSize(from: &decoder, type: vType, runtime: runtime)
        case .composite(fields: let fields):
            return try _compositeSize(from: &decoder, fields: fields, runtime: runtime)
        case .variant(variants: let vars):
            return try _variantSize(from: &decoder, type: id, variants: vars, runtime: runtime)
        }
    }
}

private extension Value {
    static func _primitiveSize<D: SkippableDecoder>(
        in decoder: inout D, prim: NetworkType.Primitive
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
        from decoder: inout D,
        store: NetworkType.Id, order: NetworkType.Id, runtime: Runtime
    ) throws -> Int {
        let format = try BitSequence.Format(store: store, order: order, runtime: runtime)
        let cCount = try Compact<UInt32>.calculateSizeNoSkip(in: &decoder)
        let bitCount = try decoder.decode(UInt32.self, .compact)
        let count = bitCount.isMultiple(of: format.store.bits)
            ? Int(bitCount / 8)
            : (Int(bitCount / format.store.bits) + 1) * Int(format.store.bits / 8)
        try decoder.skip(count: count)
        return count + cCount
    }
    
    static func _tupleSize<D: SkippableDecoder>(
        from decoder: inout D, fields: [NetworkType.Id], runtime: any Runtime
    ) throws -> Int {
        try fields.reduce(0) { sum, field in
            try sum + Self.calculateSize(in: &decoder, for: field, runtime: runtime)
        }
    }
    
    static func _arraySize<D: SkippableDecoder>(
        from decoder: inout D, count: Int, type: NetworkType.Id, runtime: any Runtime
    ) throws -> Int {
        try (0..<count).reduce(0) { sum, _ in
            try sum + Self.calculateSize(in: &decoder, for: type, runtime: runtime)
        }
    }
    
    static func _sequenceSize<D: SkippableDecoder>(
        from decoder: inout D, type: NetworkType.Id, runtime: any Runtime
    ) throws -> Int {
        try Array<Void>.calculateSize(in: &decoder) { decoder in
            try Self.calculateSize(in: &decoder, for: type, runtime: runtime)
        }
    }
    
    static func _compositeSize<D: SkippableDecoder>(
        from decoder: inout D, fields: [NetworkType.Field], runtime: any Runtime
    ) throws -> Int {
        try fields.reduce(0) { sum, field in
            try sum + Self.calculateSize(in: &decoder, for: field.type, runtime: runtime)
        }
    }
    
    static func _variantSize<D: SkippableDecoder>(
        from decoder: inout D, type: NetworkType.Id,
        variants: [NetworkType.Variant], runtime: any Runtime
    ) throws -> Int {
        let index = try decoder.decode(.enumCaseId)
        guard let variant = variants.first(where: { $0.index == index }) else {
            throw DecodingError.variantNotFound(index, type)
        }
        return try _compositeSize(from: &decoder, fields: variant.fields, runtime: runtime) + 1
    }
}
