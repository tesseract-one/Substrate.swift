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

extension Optional: DynamicTypeId {}
extension Array: DynamicTypeId {}
extension Set: DynamicTypeId {}
extension Dictionary: DynamicTypeId {}
extension Result: DynamicTypeId {}

extension Data: ScaleDynamicEncodableCollectionConvertible {
    public var encodableCollection: DEncodableCollection {
        DEncodableCollection(Array(self))
    }
}

extension CaseIterable where Self: Equatable & ScaleEncodable, Self.AllCases.Index == Int {
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try encode(in: encoder)
    }
}

extension CaseIterable where Self: Equatable & ScaleDecodable, Self.AllCases.Index == Int {
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        try self.init(from: decoder)
    }
}

extension Optional: ScaleDynamicEncodable where Wrapped: ScaleDynamicEncodable {
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try encode(in: encoder) { val, enc in
            try val.encode(in: enc, registry: registry)
        }
    }
}

extension Optional: ScaleDynamicEncodableOptionalConvertible where Wrapped: ScaleDynamicEncodable {
    public var encodableOptional: DEncodableOptional {
        DEncodableOptional(self)
    }
}

extension Optional: ScaleDynamicDecodable where Wrapped: ScaleDynamicDecodable {
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        self = try Optional<Wrapped>(from: decoder) { dec in
             try Wrapped(from: dec, registry: registry)
        }
    }
}

extension Array: ScaleDynamicEncodable where Element: ScaleDynamicEncodable {
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try encode(in: encoder) { val, enc in
            try val.encode(in: enc, registry: registry)
        }
    }
}

extension Array: ScaleDynamicEncodableCollectionConvertible where Element: ScaleDynamicEncodable {
    public var encodableCollection: DEncodableCollection {
        DEncodableCollection(self)
    }
}

extension Array: ScaleDynamicDecodable where Element: ScaleDynamicDecodable {
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        try self.init(from: decoder) { dec in
            try Element(from: dec, registry: registry)
        }
    }
}

extension Set: ScaleDynamicEncodable where Element: ScaleDynamicEncodable {
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try encode(in: encoder) { val, enc in
            try val.encode(in: enc, registry: registry)
        }
    }
}

extension Set: ScaleDynamicEncodableCollectionConvertible where Element: ScaleDynamicEncodable {
    public var encodableCollection: DEncodableCollection {
        DEncodableCollection(Array(self))
    }
}

extension Set: ScaleDynamicDecodable where Element: ScaleDynamicDecodable {
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        try self.init(from: decoder) { dec in
            try Element(from: dec, registry: registry)
        }
    }
}

extension Dictionary: ScaleDynamicEncodable where Key: ScaleDynamicEncodable, Value: ScaleDynamicEncodable {
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try encode(in: encoder, lwriter: { try $0.encode(in: $1, registry: registry) }) { val, enc in
            try val.encode(in: enc, registry: registry)
        }
    }
}

extension Dictionary: ScaleDynamicEncodableMapConvertible where Key: ScaleDynamicEncodable, Value: ScaleDynamicEncodable {
    public var encodableMap: DEncodableMap {
        DEncodableMap(self)
    }
}

extension Dictionary: ScaleDynamicDecodable
    where Key: ScaleDynamicDecodable, Value: ScaleDynamicDecodable
{
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        try self.init(from: decoder, lreader: { try Key(from: $0, registry: registry) }) { dec in
            try Value(from: dec, registry: registry)
        }
    }
}

extension Result: ScaleDynamicEncodable where Success: ScaleDynamicEncodable, Failure: ScaleDynamicEncodable {
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try encode(in: encoder, lwriter: { try $0.encode(in: $1, registry: registry) }) { err, enc in
            try err.encode(in: enc, registry: registry)
        }
    }
}

extension Result: ScaleDynamicEncodableEitherConvertible
    where Success: ScaleDynamicEncodable, Failure: ScaleDynamicEncodable
{
    public var encodableEither: DEncodableEither {
        DEncodableEither(self)
    }
}

extension Result: ScaleDynamicDecodable where Success: ScaleDynamicDecodable, Failure: ScaleDynamicDecodable {
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        try self.init(from: decoder, lreader: { try Success(from: $0, registry: registry) }) { dec in
            try Failure(from: dec, registry: registry)
        }
    }
}
