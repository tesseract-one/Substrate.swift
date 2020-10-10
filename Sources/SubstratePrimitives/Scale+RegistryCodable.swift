//
//  Scale+RegistryCodable.swift
//  
//
//  Created by Yehor Popovych on 10/10/20.
//

import Foundation
import ScaleCodec

extension Bool: ScaleRegistryCodable {}
extension Data: ScaleRegistryCodable {}
extension Int8: ScaleRegistryCodable {}
extension Int16: ScaleRegistryCodable {}
extension Int32: ScaleRegistryCodable {}
extension Int64: ScaleRegistryCodable {}
extension SInt128: ScaleRegistryCodable {}
extension SInt256: ScaleRegistryCodable {}
extension SInt512: ScaleRegistryCodable {}
extension UInt8: ScaleRegistryCodable {}
extension UInt16: ScaleRegistryCodable {}
extension UInt32: ScaleRegistryCodable {}
extension UInt64: ScaleRegistryCodable {}
extension SUInt128: ScaleRegistryCodable {}
extension SUInt256: ScaleRegistryCodable {}
extension SUInt512: ScaleRegistryCodable {}
extension SCompact: ScaleRegistryCodable {}
extension String: ScaleRegistryCodable {}

extension CaseIterable where Self: Equatable & ScaleEncodable, Self.AllCases.Index == Int {
    public func encode(in encoder: ScaleEncoder, with registry: TypeRegistry) throws {
        try encode(in: encoder)
    }
}

extension CaseIterable where Self: Equatable & ScaleDecodable, Self.AllCases.Index == Int {
    public init(from decoder: ScaleDecoder, with registry: TypeRegistry) throws {
        try self.init(from: decoder)
    }
}


extension Optional: ScaleRegistryEncodable where Wrapped: ScaleRegistryEncodable {
    public func encode(in encoder: ScaleEncoder, with registry: TypeRegistry) throws {
        try encode(in: encoder) { val, enc in
            try val.encode(in: enc, with: registry)
        }
    }
}


extension Optional: ScaleRegistryDecodable where Wrapped: ScaleRegistryDecodable {
    public init(from decoder: ScaleDecoder, with registry: TypeRegistry) throws {
        self = try Optional<Wrapped>(from: decoder) { dec in
             try Wrapped(from: dec, with: registry)
        }
    }
}

extension Array: ScaleRegistryEncodable where Element: ScaleRegistryEncodable {
    public func encode(in encoder: ScaleEncoder, with registry: TypeRegistry) throws {
        try encode(in: encoder) { val, enc in
            try val.encode(in: enc, with: registry)
        }
    }
}

extension Array: ScaleRegistryDecodable where Element: ScaleRegistryDecodable {
    public init(from decoder: ScaleDecoder, with registry: TypeRegistry) throws {
        try self.init(from: decoder) { dec in
            try Element(from: dec, with: registry)
        }
    }
}

extension Set: ScaleRegistryEncodable where Element: ScaleRegistryEncodable {
    public func encode(in encoder: ScaleEncoder, with registry: TypeRegistry) throws {
        try encode(in: encoder) { val, enc in
            try val.encode(in: enc, with: registry)
        }
    }
}

extension Set: ScaleRegistryDecodable where Element: ScaleRegistryDecodable {
    public init(from decoder: ScaleDecoder, with registry: TypeRegistry) throws {
        try self.init(from: decoder) { dec in
            try Element(from: dec, with: registry)
        }
    }
}

extension Dictionary: ScaleRegistryEncodable where Key: ScaleRegistryEncodable, Value: ScaleRegistryEncodable {
    public func encode(in encoder: ScaleEncoder, with registry: TypeRegistry) throws {
        try encode(in: encoder, lwriter: { try $0.encode(in: $1, with: registry) }) { val, enc in
            try val.encode(in: enc, with: registry)
        }
    }
}

extension Dictionary: ScaleRegistryDecodable where Key: ScaleRegistryDecodable, Value: ScaleRegistryDecodable {
    public init(from decoder: ScaleDecoder, with registry: TypeRegistry) throws {
        try self.init(from: decoder, lreader: { try Key(from: $0, with: registry) }) { dec in
            try Value(from: dec, with: registry)
        }
    }
}

extension Result: ScaleRegistryEncodable where Success: ScaleRegistryEncodable, Failure: ScaleRegistryEncodable {
    public func encode(in encoder: ScaleEncoder, with registry: TypeRegistry) throws {
        try encode(in: encoder, lwriter: { try $0.encode(in: $1, with: registry) }) { err, enc in
            try err.encode(in: enc, with: registry)
        }
    }
}

extension Result: ScaleRegistryDecodable where Success: ScaleRegistryDecodable, Failure: ScaleRegistryDecodable {
    public init(from decoder: ScaleDecoder, with registry: TypeRegistry) throws {
        try self.init(from: decoder, lreader: { try Success(from: $0, with: registry) }) { dec in
            try Failure(from: dec, with: registry)
        }
    }
}
