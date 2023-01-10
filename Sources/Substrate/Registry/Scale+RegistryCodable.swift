//
//  Scale+RegistryCodable.swift
//  
//
//  Created by Yehor Popovych on 10/10/20.
//

import Foundation
import ScaleCodec

extension Bool: RegistryScaleCodable {}
extension Data: RegistryScaleCodable {}
extension Int8: RegistryScaleCodable {}
extension Int16: RegistryScaleCodable {}
extension Int32: RegistryScaleCodable {}
extension Int64: RegistryScaleCodable {}
extension UInt8: RegistryScaleCodable {}
extension UInt16: RegistryScaleCodable {}
extension UInt32: RegistryScaleCodable {}
extension UInt64: RegistryScaleCodable {}
extension Compact: RegistryScaleCodable {}
extension String: RegistryScaleCodable {}
extension DoubleWidth: RegistryScaleCodable {}

extension CaseIterable where Self: Equatable & ScaleEncodable, Self.AllCases.Index == Int {
    public func encode(in encoder: ScaleEncoder, registry: Registry) throws {
        try encode(in: encoder)
    }
}

extension CaseIterable where Self: Equatable & ScaleDecodable, Self.AllCases.Index == Int {
    public init(from decoder: ScaleDecoder, registry: Registry) throws {
        try self.init(from: decoder)
    }
}

extension Optional: RegistryScaleEncodable where Wrapped: RegistryScaleEncodable {
    public func encode(in encoder: ScaleEncoder, registry: Registry) throws {
        try encode(in: encoder) { val, enc in
            try val.encode(in: enc, registry: registry)
        }
    }
}

extension Optional: RegistryScaleDecodable where Wrapped: RegistryScaleDecodable {
    public init(from decoder: ScaleDecoder, registry: Registry) throws {
        self = try Optional<Wrapped>(from: decoder) { dec in
             try Wrapped(from: dec, registry: registry)
        }
    }
}

extension Array: RegistryScaleEncodable where Element: RegistryScaleEncodable {
    public func encode(in encoder: ScaleEncoder, registry: Registry) throws {
        try encode(in: encoder) { val, enc in
            try val.encode(in: enc, registry: registry)
        }
    }
}

extension Array: RegistryScaleDecodable where Element: RegistryScaleDecodable {
    public init(from decoder: ScaleDecoder, registry: Registry) throws {
        try self.init(from: decoder) { dec in
            try Element(from: dec, registry: registry)
        }
    }
}

extension Set: RegistryScaleEncodable where Element: RegistryScaleEncodable {
    public func encode(in encoder: ScaleEncoder, registry: Registry) throws {
        try encode(in: encoder) { val, enc in
            try val.encode(in: enc, registry: registry)
        }
    }
}

extension Set: RegistryScaleDecodable where Element: RegistryScaleDecodable {
    public init(from decoder: ScaleDecoder, registry: Registry) throws {
        try self.init(from: decoder) { dec in
            try Element(from: dec, registry: registry)
        }
    }
}

extension Dictionary: RegistryScaleEncodable where Key: RegistryScaleEncodable, Value: RegistryScaleEncodable {
    public func encode(in encoder: ScaleEncoder, registry: Registry) throws {
        try encode(in: encoder, lwriter: { try $0.encode(in: $1, registry: registry) }) { val, enc in
            try val.encode(in: enc, registry: registry)
        }
    }
}

extension Dictionary: RegistryScaleDecodable where Key: RegistryScaleDecodable, Value: RegistryScaleDecodable
{
    public init(from decoder: ScaleDecoder, registry: Registry) throws {
        try self.init(from: decoder, lreader: { try Key(from: $0, registry: registry) }) { dec in
            try Value(from: dec, registry: registry)
        }
    }
}

extension Result: RegistryScaleEncodable where Success: RegistryScaleEncodable, Failure: RegistryScaleEncodable {
    public func encode(in encoder: ScaleEncoder, registry: Registry) throws {
        try encode(in: encoder, lwriter: { try $0.encode(in: $1, registry: registry) }) { err, enc in
            try err.encode(in: enc, registry: registry)
        }
    }
}

extension Result: RegistryScaleDecodable where Success: RegistryScaleDecodable, Failure: RegistryScaleDecodable {
    public init(from decoder: ScaleDecoder, registry: Registry) throws {
        try self.init(from: decoder, lreader: { try Success(from: $0, registry: registry) }) { dec in
            try Failure(from: dec, registry: registry)
        }
    }
}
