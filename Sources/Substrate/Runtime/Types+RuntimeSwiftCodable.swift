//
//  Types+RuntimeSwiftCodable.swift
//  
//
//  Created by Yehor Popovych on 07/07/2023.
//

import Foundation
import struct ScaleCodec.Compact
import protocol ScaleCodec.DataInitalizable
import protocol ScaleCodec.DataSerializable
import struct Numberick.NBKDoubleWidth
import ContextCodable

extension Bool: RuntimeSwiftCodable {}
extension Data: RuntimeSwiftCodable {}
extension Int8: RuntimeSwiftCodable {}
extension Int16: RuntimeSwiftCodable {}
extension Int32: RuntimeSwiftCodable {}
extension Int64: RuntimeSwiftCodable {}
extension UInt8: RuntimeSwiftCodable {}
extension UInt16: RuntimeSwiftCodable {}
extension UInt32: RuntimeSwiftCodable {}
extension UInt64: RuntimeSwiftCodable {}
extension String: RuntimeSwiftCodable {}
extension Date: RuntimeSwiftCodable {}
extension Compact: ContextEncodable where T.UI: DataSerializable & Encodable {}
extension Compact: ContextDecodable where T.UI: DataInitalizable & Decodable {}
extension Compact: RuntimeSwiftDecodable where T.UI: DataInitalizable & Decodable {}
extension Compact: RuntimeSwiftEncodable where T.UI: DataSerializable & Encodable {}
extension NBKDoubleWidth: ContextCodable where Self: UnsignedInteger {}
extension NBKDoubleWidth: RuntimeSwiftCodable where Self: UnsignedInteger {}

extension Optional: ContextEncodable where Wrapped: RuntimeSwiftEncodable {}
extension Optional: RuntimeSwiftEncodable where Wrapped: RuntimeSwiftEncodable {
    public func encode(to encoder: Encoder, runtime: any Runtime) throws {
        if let value = self {
            try value.encode(to: encoder, runtime: runtime)
        } else {
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        }
    }
}

extension Optional: ContextDecodable where Wrapped: RuntimeSwiftDecodable {}
extension Optional: RuntimeSwiftDecodable where Wrapped: RuntimeSwiftDecodable {
    public init(from decoder: Decoder, runtime: any Runtime) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = nil
        } else {
            self = try Wrapped(from: decoder, runtime: runtime)
        }
    }
}

extension Array: ContextEncodable where Element: RuntimeSwiftEncodable {}
extension Array: RuntimeSwiftEncodable where Element: RuntimeSwiftEncodable {
    public func encode(to encoder: Encoder, runtime: any Runtime) throws {
        var container = encoder.unkeyedContainer()
        for value in self {
            try container.encode(value,
                                 context: RuntimeSwiftCodableContext(runtime: runtime))
        }
    }
}

extension Array: ContextDecodable where Element: RuntimeSwiftDecodable {}
extension Array: RuntimeSwiftDecodable where Element: RuntimeSwiftDecodable {
    public init(from decoder: Decoder, runtime: any Runtime) throws {
        var container = try decoder.unkeyedContainer()
        var array = Array<Element>()
        if let count = container.count { array.reserveCapacity(count) }
        while !container.isAtEnd {
            try array.append(
                container.decode(Element.self,
                                 context: RuntimeSwiftCodableContext(runtime: runtime))
            )
        }
        self = array
    }
}

extension Set: ContextEncodable where Element: RuntimeSwiftEncodable {}
extension Set: RuntimeSwiftEncodable where Element: RuntimeSwiftEncodable {
    public func encode(to encoder: Encoder, runtime: any Runtime) throws {
        var container = encoder.unkeyedContainer()
        for value in self {
            try container.encode(value,
                                 context: RuntimeSwiftCodableContext(runtime: runtime))
        }
    }
}

extension Set: ContextDecodable where Element: RuntimeSwiftDecodable {}
extension Set: RuntimeSwiftDecodable where Element: RuntimeSwiftDecodable {
    public init(from decoder: Decoder, runtime: any Runtime) throws {
        var container = try decoder.unkeyedContainer()
        var array = Array<Element>()
        if let count = container.count { array.reserveCapacity(count) }
        while !container.isAtEnd {
            try array.append(
                container.decode(Element.self,
                                 context: RuntimeSwiftCodableContext(runtime: runtime))
            )
        }
        self = Set(array)
    }
}

extension Dictionary: ContextEncodable where Key: StringProtocol, Value: RuntimeSwiftEncodable {}
extension Dictionary: RuntimeSwiftEncodable where Key: StringProtocol, Value: RuntimeSwiftEncodable {
    public func encode(to encoder: Encoder, runtime: any Runtime) throws {
        var container = encoder.container(keyedBy: AnyCodableCodingKey.self)
        for (key, val) in self {
            try container.encode(val, forKey: AnyCodableCodingKey(String(key)),
                                 context: RuntimeSwiftCodableContext(runtime: runtime))
        }
    }
}

extension Dictionary: ContextDecodable where Key: StringProtocol, Value: RuntimeSwiftDecodable {}
extension Dictionary: RuntimeSwiftDecodable where Key: StringProtocol, Value: RuntimeSwiftDecodable
{
    public init(from decoder: Decoder, runtime: any Runtime) throws {
        let container = try decoder.container(keyedBy: AnyCodableCodingKey.self)
        let allKeys = container.allKeys
        var dict = Dictionary<Key, Value>()
        dict.reserveCapacity(allKeys.count)
        for key in allKeys {
            dict[Key(stringLiteral: key.stringValue)] = try container.decode(
                Value.self, forKey: key, context: RuntimeSwiftCodableContext(runtime: runtime)
            )
        }
        self = dict
    }
}

private extension Result {
    enum Keys: String, CodingKey {
        case ok = "Ok"
        case err = "Err"
    }
}

extension Result: ContextEncodable where Success: RuntimeSwiftEncodable, Failure: RuntimeSwiftEncodable {}
extension Result: RuntimeSwiftEncodable where Success: RuntimeSwiftEncodable, Failure: RuntimeSwiftEncodable {
    public func encode(to encoder: Encoder, runtime: any Runtime) throws {
        var container = encoder.container(keyedBy: Keys.self)
        switch self {
        case .success(let val):
            try container.encode(val, forKey: .ok,
                                 context: RuntimeSwiftCodableContext(runtime: runtime))
        case .failure(let err):
            try container.encode(err, forKey: .err,
                                 context: RuntimeSwiftCodableContext(runtime: runtime))
        }
    }
}

extension Result: ContextDecodable where Success: RuntimeSwiftDecodable, Failure: RuntimeSwiftDecodable {}
extension Result: RuntimeSwiftDecodable where Success: RuntimeSwiftDecodable, Failure: RuntimeSwiftDecodable {
    public init(from decoder: Decoder, runtime: any Runtime) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        if container.contains(.ok) {
            self = try .success(
                container.decode(Success.self, forKey: .ok,
                                 context: RuntimeSwiftCodableContext(runtime: runtime))
            )
        } else if container.contains(.err) {
            self = try .failure(
                container.decode(Failure.self, forKey: .err,
                                 context: RuntimeSwiftCodableContext(runtime: runtime))
            )
        } else {
            throw DecodingError.keyNotFound(Keys.ok, .init(codingPath: container.codingPath,
                                                           debugDescription: "No Ok and Err keys"))
        }
    }
}
