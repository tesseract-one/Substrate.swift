//
//  Types+SwiftCodable.swift
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

extension Bool: RuntimeSwiftCodable, RuntimeDynamicSwiftCodable, DynamicSwiftCodable {
    public typealias DecodingContext = VoidCodableContext
    public typealias EncodingContext = VoidCodableContext
}
extension Data: RuntimeSwiftCodable, RuntimeDynamicSwiftCodable, DynamicSwiftCodable {
    public typealias DecodingContext = VoidCodableContext
    public typealias EncodingContext = VoidCodableContext
}
extension Int8: RuntimeSwiftCodable, RuntimeDynamicSwiftCodable, DynamicSwiftCodable {
    public typealias DecodingContext = VoidCodableContext
    public typealias EncodingContext = VoidCodableContext
}
extension Int16: RuntimeSwiftCodable, RuntimeDynamicSwiftCodable, DynamicSwiftCodable {
    public typealias DecodingContext = VoidCodableContext
    public typealias EncodingContext = VoidCodableContext
}
extension Int32: RuntimeSwiftCodable, RuntimeDynamicSwiftCodable, DynamicSwiftCodable {
    public typealias DecodingContext = VoidCodableContext
    public typealias EncodingContext = VoidCodableContext
}
extension Int64: RuntimeSwiftCodable, RuntimeDynamicSwiftCodable, DynamicSwiftCodable {
    public typealias DecodingContext = VoidCodableContext
    public typealias EncodingContext = VoidCodableContext
}
extension UInt8: RuntimeSwiftCodable, RuntimeDynamicSwiftCodable, DynamicSwiftCodable {
    public typealias DecodingContext = VoidCodableContext
    public typealias EncodingContext = VoidCodableContext
}
extension UInt16: RuntimeSwiftCodable, RuntimeDynamicSwiftCodable, DynamicSwiftCodable {
    public typealias DecodingContext = VoidCodableContext
    public typealias EncodingContext = VoidCodableContext
}
extension UInt32: RuntimeSwiftCodable, RuntimeDynamicSwiftCodable, DynamicSwiftCodable {
    public typealias DecodingContext = VoidCodableContext
    public typealias EncodingContext = VoidCodableContext
}
extension UInt64: RuntimeSwiftCodable, RuntimeDynamicSwiftCodable, DynamicSwiftCodable {
    public typealias DecodingContext = VoidCodableContext
    public typealias EncodingContext = VoidCodableContext
}
extension String: RuntimeSwiftCodable, RuntimeDynamicSwiftCodable, DynamicSwiftCodable {
    public typealias DecodingContext = VoidCodableContext
    public typealias EncodingContext = VoidCodableContext
}
extension Date: RuntimeSwiftCodable, RuntimeDynamicSwiftCodable, DynamicSwiftCodable {
    public typealias DecodingContext = VoidCodableContext
    public typealias EncodingContext = VoidCodableContext
}
extension Compact: ContextEncodable where T.UI: DataSerializable & Encodable {
    public typealias EncodingContext = VoidCodableContext
}
extension Compact: ContextDecodable where T.UI: DataInitalizable & Decodable {
    public typealias DecodingContext = VoidCodableContext
}
extension Compact: RuntimeSwiftDecodable where T.UI: DataInitalizable & Decodable {}
extension Compact: RuntimeSwiftEncodable where T.UI: DataSerializable & Encodable {}
extension Compact: RuntimeDynamicSwiftDecodable where T.UI: DataInitalizable & Decodable {}
extension Compact: RuntimeDynamicSwiftEncodable where T.UI: DataSerializable & Encodable {}
extension Compact: DynamicSwiftDecodable where T.UI: DataInitalizable & Decodable {}
extension Compact: DynamicSwiftEncodable where T.UI: DataSerializable & Encodable {}
extension NBKDoubleWidth: ContextCodable where Self: UnsignedInteger {
    public typealias DecodingContext = VoidCodableContext
    public typealias EncodingContext = VoidCodableContext
}
extension NBKDoubleWidth: RuntimeSwiftCodable where Self: UnsignedInteger {}
extension NBKDoubleWidth: RuntimeDynamicSwiftCodable where Self: UnsignedInteger {}
extension NBKDoubleWidth: DynamicSwiftCodable where Self: UnsignedInteger {}

extension Optional: ContextEncodable where Wrapped: ContextEncodable {
    public typealias EncodingContext = Wrapped.EncodingContext
    
    public func encode(to encoder: Encoder, context: Wrapped.EncodingContext) throws {
        if let value = self {
            try value.encode(to: encoder, context: context)
        } else {
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        }
    }
}
extension Optional: RuntimeSwiftEncodable where
    Wrapped: RuntimeSwiftEncodable,
    Wrapped.EncodingContext == RuntimeCodableContext
{
    public func encode(to encoder: Encoder, runtime: Runtime) throws {
       try encode(to: encoder, context: .init(runtime: runtime))
    }
}
extension Optional: RuntimeDynamicSwiftEncodable where
    Wrapped: RuntimeDynamicSwiftEncodable,
    Wrapped.EncodingContext == RuntimeDynamicCodableContext
{
    public func encode(to encoder: Encoder, as type: TypeDefinition,
                       runtime: any Runtime) throws
    {
        try encode(to: encoder, context: .init(runtime: runtime, type: type))
    }
}
extension Optional: DynamicSwiftEncodable where
    Wrapped: DynamicSwiftEncodable,
    Wrapped.EncodingContext == DynamicCodableContext
{
    public func encode(to encoder: Encoder, as type: TypeDefinition) throws {
        try encode(to: encoder, context: .init(type: type))
    }
}

extension Optional: ContextDecodable where Wrapped: ContextDecodable {
    public typealias DecodingContext = Wrapped.DecodingContext
    
    public init(from decoder: Decoder, context: Wrapped.DecodingContext) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = nil
        } else {
            self = try Wrapped(from: decoder, context: context)
        }
    }
}
extension Optional: RuntimeSwiftDecodable where
    Wrapped: RuntimeSwiftDecodable, Wrapped.DecodingContext == RuntimeCodableContext
{
    public init(from decoder: Decoder, runtime: any Runtime) throws {
        self = try Self(from: decoder,
                        context: .init(runtime: runtime))
    }
}
extension Optional: RuntimeDynamicSwiftDecodable where
    Wrapped: RuntimeDynamicSwiftDecodable,
    Wrapped.DecodingContext == RuntimeDynamicCodableContext
{
    public init(from decoder: Decoder, as type: TypeDefinition, runtime: any Runtime) throws {
        self = try Self(from: decoder,
                        context: .init(runtime: runtime, type: type))
    }
}
extension Optional: DynamicSwiftDecodable where
    Wrapped: DynamicSwiftDecodable, Wrapped.DecodingContext == DynamicCodableContext
{
    public init(from decoder: Decoder, as type: TypeDefinition) throws {
        self = try Self(from: decoder, context: .init(type: type))
    }
}

extension Array: ContextEncodable where Element: ContextEncodable {
    public typealias EncodingContext = Element.EncodingContext
    
    public func encode(to encoder: Encoder, context: Element.EncodingContext) throws {
        var container = encoder.unkeyedContainer()
        for value in self {
            try container.encode(value, context: context)
        }
    }
}
extension Array: RuntimeSwiftEncodable where
    Element: RuntimeSwiftEncodable, Element.EncodingContext == RuntimeCodableContext
{
    public func encode(to encoder: Encoder, runtime: any Runtime) throws {
        try encode(to: encoder, context: .init(runtime: runtime))
    }
}
extension Array: RuntimeDynamicSwiftEncodable where
    Element: RuntimeDynamicSwiftEncodable,
    Element.EncodingContext == RuntimeDynamicCodableContext
{
    public func encode(to encoder: Encoder, as type: TypeDefinition,
                       runtime: Runtime) throws {
        try encode(to: encoder, context: .init(runtime: runtime, type: type))
    }
}
extension Array: DynamicSwiftEncodable where
    Element: DynamicSwiftEncodable, Element.EncodingContext == DynamicCodableContext
{
    public func encode(to encoder: Encoder, as type: TypeDefinition) throws {
        try encode(to: encoder, context: .init(type: type))
    }
}

extension Array: ContextDecodable where Element: ContextDecodable {
    public typealias DecodingContext = Element.DecodingContext
    
    public init(from decoder: Decoder, context: Element.DecodingContext) throws {
        var container = try decoder.unkeyedContainer()
        var array = Array<Element>()
        if let count = container.count { array.reserveCapacity(count) }
        while !container.isAtEnd {
            try array.append(container.decode(Element.self, context: context))
        }
        self = array
    }
}
extension Array: RuntimeSwiftDecodable where
    Element: RuntimeSwiftDecodable,
    Element.DecodingContext == RuntimeCodableContext
{
    @inlinable
    public init(from decoder: Decoder, runtime: any Runtime) throws {
        try self.init(from: decoder, context: .init(runtime: runtime))
    }
}
extension Array: RuntimeDynamicSwiftDecodable where
    Element: RuntimeDynamicSwiftDecodable,
    Element.DecodingContext == RuntimeDynamicCodableContext
{
    public init(from decoder: Decoder, as type: TypeDefinition, runtime: Runtime) throws {
        try self.init(from: decoder, context: .init(runtime: runtime, type: type))
    }
}
extension Array: DynamicSwiftDecodable where
    Element: DynamicSwiftDecodable, Element.DecodingContext == DynamicCodableContext
{
    public init(from decoder: Decoder, as type: TypeDefinition) throws {
        try self.init(from: decoder, context: .init(type: type))
    }
}
