//
//  Value+Size.swift
//  
//
//  Created by Yehor Popovych on 22/06/2023.
//

import Foundation
import ScaleCodec


public extension Value {
    @inlinable
    static func calculateSize(
        in decoder: ScaleCodec.Decoder, for type: TypeDefinition
    ) throws -> Int {
        var skippable = decoder.skippable()
        return try calculateSize(in: &skippable, for: type)
    }
    
    static func calculateSize<D: SkippableDecoder>(
        in decoder: inout D, for type: TypeDefinition
    ) throws -> Int {
        switch type.definition {
        case .primitive(is: let pType): return try _primitiveSize(in: &decoder, prim: pType)
        case .compact(of: _): return try _compactSize(in: &decoder)
        case .bitsequence(format: let format):
            return try _bitSequenceSize(from: &decoder, format: format)
        case .array(count: let count, of: let vType):
            return try _arraySize(from: &decoder, count: Int(count), type: vType)
        case .sequence(of: let vType):
            return try _sequenceSize(from: &decoder, type: vType)
        case .composite(fields: let fields):
            return try _compositeSize(from: &decoder, fields: fields)
        case .variant(variants: let vars):
            return try _variantSize(from: &decoder, type: type, variants: vars)
        case .void: return 0
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
        from decoder: inout D, format: BitSequence.Format
    ) throws -> Int {
        let cCount = try Compact<UInt32>.calculateSizeNoSkip(in: &decoder)
        let bitCount = try decoder.decode(UInt32.self, .compact)
        let count = bitCount.isMultiple(of: format.store.bits)
            ? Int(bitCount / 8)
            : (Int(bitCount / format.store.bits) + 1) * Int(format.store.bits / 8)
        try decoder.skip(count: count)
        return count + cCount
    }
    
    static func _arraySize<D: SkippableDecoder>(
        from decoder: inout D, count: Int, type: TypeDefinition
    ) throws -> Int {
        try (0..<count).reduce(0) { sum, _ in
            try sum + Self.calculateSize(in: &decoder, for: type)
        }
    }
    
    static func _sequenceSize<D: SkippableDecoder>(
        from decoder: inout D, type: TypeDefinition
    ) throws -> Int {
        try Array<Void>.calculateSize(in: &decoder) { decoder in
            try Self.calculateSize(in: &decoder, for: type)
        }
    }
    
    static func _compositeSize<D: SkippableDecoder>(
        from decoder: inout D, fields: [TypeDefinition.Field]
    ) throws -> Int {
        try fields.reduce(0) { sum, field in
            try sum + Self.calculateSize(in: &decoder, for: field.type)
        }
    }
    
    static func _variantSize<D: SkippableDecoder>(
        from decoder: inout D, type: TypeDefinition,
        variants: [TypeDefinition.Variant]
    ) throws -> Int {
        let index = try decoder.decode(.enumCaseId)
        guard let variant = variants.first(where: { $0.index == index }) else {
            throw DecodingError.variantNotFound(index, type.strong)
        }
        return try _compositeSize(from: &decoder, fields: variant.fields) + 1
    }
}
