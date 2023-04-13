//
//  Types+RuntimeCodable.swift
//  
//
//  Created by Yehor Popovych on 10/10/20.
//

import Foundation
import ScaleCodec
import Serializable

extension Bool: ScaleRuntimeCodable {}
extension Data: ScaleRuntimeCodable {}
extension Int8: ScaleRuntimeCodable {}
extension Int16: ScaleRuntimeCodable {}
extension Int32: ScaleRuntimeCodable {}
extension Int64: ScaleRuntimeCodable {}
extension UInt8: ScaleRuntimeCodable {}
extension UInt16: ScaleRuntimeCodable {}
extension UInt32: ScaleRuntimeCodable {}
extension UInt64: ScaleRuntimeCodable {}
extension String: ScaleRuntimeCodable {}
extension Compact: ScaleRuntimeCodable {}
extension DoubleWidth: ScaleRuntimeCodable {}

extension CaseIterable where Self: Equatable & ScaleEncodable, Self.AllCases.Index == Int {
    public func encode(in encoder: ScaleEncoder, runtime: Runtime) throws {
        try encode(in: encoder)
    }
}

extension CaseIterable where Self: Equatable & ScaleDecodable, Self.AllCases.Index == Int {
    public init(from decoder: ScaleDecoder, runtime: Runtime) throws {
        try self.init(from: decoder)
    }
}

extension Optional: ScaleRuntimeEncodable where Wrapped: ScaleRuntimeEncodable {
    public func encode(in encoder: ScaleEncoder, runtime: Runtime) throws {
        try encode(in: encoder) { val, enc in
            try val.encode(in: enc, runtime: runtime)
        }
    }
}

extension Optional: ScaleRuntimeDecodable where Wrapped: ScaleRuntimeDecodable {
    public init(from decoder: ScaleDecoder, runtime: Runtime) throws {
        self = try Optional<Wrapped>(from: decoder) { dec in
             try Wrapped(from: dec, runtime: runtime)
        }
    }
}

extension Array: ScaleRuntimeEncodable where Element: ScaleRuntimeEncodable {
    public func encode(in encoder: ScaleEncoder, runtime: Runtime) throws {
        try encode(in: encoder) { val, enc in
            try val.encode(in: enc, runtime: runtime)
        }
    }
}

extension Array: ScaleRuntimeDecodable where Element: ScaleRuntimeDecodable {
    public init(from decoder: ScaleDecoder, runtime: Runtime) throws {
        try self.init(from: decoder) { dec in
            try Element(from: dec, runtime: runtime)
        }
    }
}

extension Set: ScaleRuntimeEncodable where Element: ScaleRuntimeEncodable {
    public func encode(in encoder: ScaleEncoder, runtime: Runtime) throws {
        try encode(in: encoder) { val, enc in
            try val.encode(in: enc, runtime: runtime)
        }
    }
}

extension Set: ScaleRuntimeDecodable where Element: ScaleRuntimeDecodable {
    public init(from decoder: ScaleDecoder, runtime: Runtime) throws {
        try self.init(from: decoder) { dec in
            try Element(from: dec, runtime: runtime)
        }
    }
}

extension Dictionary: ScaleRuntimeEncodable where Key: ScaleRuntimeEncodable, Value: ScaleRuntimeEncodable {
    public func encode(in encoder: ScaleEncoder, runtime: Runtime) throws {
        try encode(in: encoder, lwriter: { try $0.encode(in: $1, runtime: runtime) }) { val, enc in
            try val.encode(in: enc, runtime: runtime)
        }
    }
}

extension Dictionary: ScaleRuntimeDecodable where Key: ScaleRuntimeDecodable, Value: ScaleRuntimeDecodable
{
    public init(from decoder: ScaleDecoder, runtime: Runtime) throws {
        try self.init(from: decoder, lreader: { try Key(from: $0, runtime: runtime) }) { dec in
            try Value(from: dec, runtime: runtime)
        }
    }
}

extension Result: ScaleRuntimeEncodable where Success: ScaleRuntimeEncodable, Failure: ScaleRuntimeEncodable {
    public func encode(in encoder: ScaleEncoder, runtime: Runtime) throws {
        try encode(in: encoder, lwriter: { try $0.encode(in: $1, runtime: runtime) }) { err, enc in
            try err.encode(in: enc, runtime: runtime)
        }
    }
}

extension Result: ScaleRuntimeDecodable where Success: ScaleRuntimeDecodable, Failure: ScaleRuntimeDecodable {
    public init(from decoder: ScaleDecoder, runtime: Runtime) throws {
        try self.init(from: decoder, lreader: { try Success(from: $0, runtime: runtime) }) { dec in
            try Failure(from: dec, runtime: runtime)
        }
    }
}
