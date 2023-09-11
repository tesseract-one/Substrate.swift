//
//  Types+Codable.swift
//  
//
//  Created by Yehor Popovych on 10/10/20.
//

import Foundation
import ScaleCodec
import Numberick

extension Bool: DynamicCodable, RuntimeCodable {}
extension Data: DynamicCodable, RuntimeCodable {}
extension Int8: DynamicCodable, RuntimeCodable {}
extension Int16: DynamicCodable, RuntimeCodable {}
extension Int32: DynamicCodable, RuntimeCodable {}
extension Int64: DynamicCodable, RuntimeCodable {}
extension UInt8: DynamicCodable, RuntimeCodable {}
extension UInt16: DynamicCodable, RuntimeCodable {}
extension UInt32: DynamicCodable, RuntimeCodable {}
extension UInt64: DynamicCodable, RuntimeCodable {}
extension String: DynamicCodable, RuntimeCodable {}
extension Compact: DynamicCodable, RuntimeCodable {}
extension NBKDoubleWidth: DynamicCodable, RuntimeCodable {}

extension CaseIterable where Self: Equatable & ScaleCodec.Encodable, Self.AllCases.Index == Int {
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
        try encode(in: &encoder)
    }
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E, as type: TypeDefinition) throws {
        try encode(in: &encoder)
    }
}

extension CaseIterable where Self: Equatable & ScaleCodec.Decodable, Self.AllCases.Index == Int {
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws {
        try self.init(from: &decoder)
    }
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, as type: TypeDefinition) throws {
        try self.init(from: &decoder)
    }
}

extension Optional: RuntimeLazyDynamicEncodable where Wrapped: RuntimeLazyDynamicEncodable {}
extension Optional: RuntimeEncodable where Wrapped: RuntimeEncodable {
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
        try encode(in: &encoder) { val, enc in
            try val.encode(in: &enc, runtime: runtime)
        }
    }
}

extension Optional: RuntimeLazyDynamicDecodable where Wrapped: RuntimeLazyDynamicDecodable {}
extension Optional: RuntimeDecodable where Wrapped: RuntimeDecodable {
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws {
        self = try Optional<Wrapped>(from: &decoder) { dec in
             try Wrapped(from: &dec, runtime: runtime)
        }
    }
}

extension Array: RuntimeLazyDynamicEncodable where Element: RuntimeLazyDynamicEncodable {}
extension Array: RuntimeEncodable where Element: RuntimeEncodable {
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
        try encode(in: &encoder) { val, enc in
            try val.encode(in: &enc, runtime: runtime)
        }
    }
}

extension Array: RuntimeLazyDynamicDecodable where Element: RuntimeLazyDynamicDecodable {}
extension Array: RuntimeDecodable where Element: RuntimeDecodable {
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws {
        try self.init(from: &decoder) { dec in
            try Element(from: &dec, runtime: runtime)
        }
    }
}

extension Dictionary: RuntimeLazyDynamicEncodable where Key: RuntimeLazyDynamicEncodable,
                                                        Value: RuntimeLazyDynamicEncodable {}
extension Dictionary: RuntimeEncodable where Key: RuntimeEncodable, Value: RuntimeEncodable {
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
        try encode(in: &encoder, lwriter: { try $0.encode(in: &$1, runtime: runtime) }) { val, enc in
            try val.encode(in: &enc, runtime: runtime)
        }
    }
}

extension Dictionary: RuntimeLazyDynamicDecodable where Key: RuntimeLazyDynamicDecodable,
                                                        Value: RuntimeLazyDynamicDecodable {}
extension Dictionary: RuntimeDecodable where Key: RuntimeDecodable, Value: RuntimeDecodable
{
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws {
        try self.init(from: &decoder, lreader: { try Key(from: &$0, runtime: runtime) }) { dec in
            try Value(from: &dec, runtime: runtime)
        }
    }
}

extension Result: RuntimeLazyDynamicEncodable where Success: RuntimeLazyDynamicEncodable,
                                                    Failure: RuntimeLazyDynamicEncodable {}
extension Result: RuntimeEncodable where Success: RuntimeEncodable, Failure: RuntimeEncodable {
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
        try encode(in: &encoder, lwriter: { try $0.encode(in: &$1, runtime: runtime) }) { err, enc in
            try err.encode(in: &enc, runtime: runtime)
        }
    }
}

extension Result: RuntimeLazyDynamicDecodable where Success: RuntimeLazyDynamicDecodable,
                                                    Failure: RuntimeLazyDynamicDecodable {}
extension Result: RuntimeDecodable where Success: RuntimeDecodable, Failure: RuntimeDecodable {
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws {
        try self.init(from: &decoder, lreader: { try Success(from: &$0, runtime: runtime) }) { dec in
            try Failure(from: &dec, runtime: runtime)
        }
    }
}
