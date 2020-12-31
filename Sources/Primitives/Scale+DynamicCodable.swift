//
//  Scale+DynamicCodable.swift
//  
//
//  Created by Yehor Popovych on 10/10/20.
//

import Foundation
import ScaleCodec

extension Bool: ScaleDynamicCodable {}
extension Data: ScaleDynamicCodable {}
extension Int8: ScaleDynamicCodable {}
extension Int16: ScaleDynamicCodable {}
extension Int32: ScaleDynamicCodable {}
extension Int64: ScaleDynamicCodable {}
extension SInt128: ScaleDynamicCodable {}
extension SInt256: ScaleDynamicCodable {}
extension SInt512: ScaleDynamicCodable {}
extension UInt8: ScaleDynamicCodable {}
extension UInt16: ScaleDynamicCodable {}
extension UInt32: ScaleDynamicCodable {}
extension UInt64: ScaleDynamicCodable {}
extension SUInt128: ScaleDynamicCodable {}
extension SUInt256: ScaleDynamicCodable {}
extension SUInt512: ScaleDynamicCodable {}
extension SCompact: ScaleDynamicCodable {}
extension String: ScaleDynamicCodable {}

extension CaseIterable where Self: Equatable & ScaleEncodable, Self.AllCases.Index == Int {
    public func encode(in encoder: ScaleEncoder, meta: MetadataProtocol) throws {
        try encode(in: encoder)
    }
}

extension CaseIterable where Self: Equatable & ScaleDecodable, Self.AllCases.Index == Int {
    public init(from decoder: ScaleDecoder, meta: MetadataProtocol) throws {
        try self.init(from: decoder)
    }
}

extension Optional: ScaleDynamicEncodable where Wrapped: ScaleDynamicEncodable {
    public func encode(in encoder: ScaleEncoder, meta: MetadataProtocol) throws {
        try encode(in: encoder) { val, enc in
            try val.encode(in: enc, meta: meta)
        }
    }
}

extension Optional: ScaleDynamicDecodable where Wrapped: ScaleDynamicDecodable {
    public init(from decoder: ScaleDecoder, meta: MetadataProtocol) throws {
        self = try Optional<Wrapped>(from: decoder) { dec in
             try Wrapped(from: dec, meta: meta)
        }
    }
}

extension Array: ScaleDynamicEncodable where Element: ScaleDynamicEncodable {
    public func encode(in encoder: ScaleEncoder, meta: MetadataProtocol) throws {
        try encode(in: encoder) { val, enc in
            try val.encode(in: enc, meta: meta)
        }
    }
}

extension Array: ScaleDynamicDecodable where Element: ScaleDynamicDecodable {
    public init(from decoder: ScaleDecoder, meta: MetadataProtocol) throws {
        try self.init(from: decoder) { dec in
            try Element(from: dec, meta: meta)
        }
    }
}

extension Set: ScaleDynamicEncodable where Element: ScaleDynamicEncodable {
    public func encode(in encoder: ScaleEncoder, meta: MetadataProtocol) throws {
        try encode(in: encoder) { val, enc in
            try val.encode(in: enc, meta: meta)
        }
    }
}

extension Set: ScaleDynamicDecodable where Element: ScaleDynamicDecodable {
    public init(from decoder: ScaleDecoder, meta: MetadataProtocol) throws {
        try self.init(from: decoder) { dec in
            try Element(from: dec, meta: meta)
        }
    }
}

extension Dictionary: ScaleDynamicEncodable where Key: ScaleDynamicEncodable, Value: ScaleDynamicEncodable {
    public func encode(in encoder: ScaleEncoder, meta: MetadataProtocol) throws {
        try encode(in: encoder, lwriter: { try $0.encode(in: $1, meta: meta) }) { val, enc in
            try val.encode(in: enc, meta: meta)
        }
    }
}

extension Dictionary: ScaleDynamicDecodable where Key: ScaleDynamicDecodable, Value: ScaleDynamicDecodable {
    public init(from decoder: ScaleDecoder, meta: MetadataProtocol) throws {
        try self.init(from: decoder, lreader: { try Key(from: $0, meta: meta) }) { dec in
            try Value(from: dec, meta: meta)
        }
    }
}

extension Result: ScaleDynamicEncodable where Success: ScaleDynamicEncodable, Failure: ScaleDynamicEncodable {
    public func encode(in encoder: ScaleEncoder, meta: MetadataProtocol) throws {
        try encode(in: encoder, lwriter: { try $0.encode(in: $1, meta: meta) }) { err, enc in
            try err.encode(in: enc, meta: meta)
        }
    }
}

extension Result: ScaleDynamicDecodable where Success: ScaleDynamicDecodable, Failure: ScaleDynamicDecodable {
    public init(from decoder: ScaleDecoder, meta: MetadataProtocol) throws {
        try self.init(from: decoder, lreader: { try Success(from: $0, meta: meta) }) { dec in
            try Failure(from: dec, meta: meta)
        }
    }
}
