//
//  Value.swift
//  
//
//  Created by Yehor Popovych on 09.01.2023.
//

import Foundation
import ScaleCodec

public struct Value<C> {
    public enum Def {
        case map(_ fields: [String: Value<C>])
        case sequence(_ values: [Value<C>])
        case variant(Variant)
        case primitive(Primitive)
        case bitSequence(BitSequence)
    }
    
    public enum Variant {
        case map(name: String, fields: [String: Value<C>])
        case sequence(name: String, values: [Value<C>])
    }
    
    public enum Primitive: Hashable, Equatable {
        /// A boolean value.
        case bool(Bool)
        /// A single character. (char in Rust)
        case char(Character)
        /// A string.
        case string(String)
        /// An unsigned 256 bit number.
        case u256(UInt256)
        /// A signed 256 bit number
        case i256(Int256)
        /// Bytes (u8 array or AccountId etc.)
        case bytes(Data)
    }
    
    public let value: Def
    public let context: C
    
    public init(value: Def, context: C) {
        self.value = value
        self.context = context
    }
}

extension Value {
    public var map: [String: Self]? {
        switch value {
        case .map(let val): return val
        default: return nil
        }
    }
    
    public var sequence: [Self]? {
        switch value {
        case .sequence(let val): return val
        case .map(let val): return Array(val.values)
        default: return nil
        }
    }
    
    public var variant: Variant? {
        switch value {
        case .variant(let v): return v
        default: return nil
        }
    }
    
    public var bitSequence: BitSequence? {
        switch value {
        case .bitSequence(let seq): return seq
        default: return nil
        }
    }
    
    public var bool: Bool? {
        switch value {
        case .primitive(let p):
            switch p {
            case .bool(let b): return b
            default: return nil
            }
        default: return nil
        }
    }
    
    public var char: Character? {
        switch value {
        case .primitive(let p):
            switch p {
            case .char(let c): return c
            default: return nil
            }
        default: return nil
        }
    }
    
    public var string: String? {
        switch value {
        case .primitive(let p):
            switch p {
            case .string(let s): return s
            default: return nil
            }
        default: return nil
        }
    }
    
    public var u256: UInt256? {
        switch value {
        case .primitive(let p):
            switch p {
            case .u256(let u): return u
            default: return nil
            }
        default: return nil
        }
    }
    
    public var i256: Int256? {
        switch value {
        case .primitive(let p):
            switch p {
            case .i256(let i): return i
            default: return nil
            }
        default: return nil
        }
    }
    
    public var bytes: Data? {
        switch value {
        case .primitive(let p):
            switch p {
            case .bytes(let b): return b
            default: return nil
            }
        case .sequence(let vals):
            let arr = vals.compactMap { $0.u256.flatMap { UInt8(exactly: $0) } }
            guard arr.count == vals.count else { return nil }
            return Data(arr)
        default: return nil
        }
    }
}

extension Value {
    public func removingContext() -> Value<()> {
        mapContext { _ in }
    }
    
    public func mapContext<NC>(with mapper: @escaping (C) throws -> NC) rethrows -> Value<NC> {
        try Value<NC>(value: value.mapContext(with: mapper), context: mapper(context))
    }
}

extension Value where C == Void {
    public static func map<CL: Collection>(_ seq: CL) -> Self where CL.Element == (String, Value<C>) {
        Self(value: .map(Dictionary(uniqueKeysWithValues: seq)), context: ())
    }
    
    public static func map(_ map: [String: Value<C>]) -> Self {
        Self(value: .map(map), context: ())
    }
    
    public static func sequence<CL: Collection>(_ seq: CL) -> Self where CL.Element == Value<C> {
        Self(value: .sequence(Array(seq)), context: ())
    }
    
    public static func variant<CL: Collection>(name: String, fields: CL) -> Self
        where  CL.Element == (String, Value<C>)
    {
        .variant(name: name, fields: Dictionary(uniqueKeysWithValues: fields))
    }
    
    public static func variant(name: String, fields: [String: Value<C>]) -> Self {
        Self(value: .variant(.map(name: name,
                                  fields: fields)),
             context: ())
    }
    
    public static func variant<CL: Collection>(name: String, values: CL) -> Self
        where CL.Element == Value<C>
    {
        Self(value: .variant(.sequence(name: name, values: Array(values))),
             context: ())
    }
    
    public static func bits<CL: Collection>(_ seq: CL) -> Self where CL.Element == Bool {
        Self(value: .bitSequence(BitSequence(seq)), context: ())
    }
    
    public static func bool(_ val: Bool) -> Self {
        Self(value: .primitive(.bool(val)), context: ())
    }
    
    public static func char(_ val: Character) -> Self {
        Self(value: .primitive(.char(val)), context: ())
    }
    
    public static func string(_ val: String) -> Self {
        Self(value: .primitive(.string(val)), context: ())
    }
    
    public static func u256(_ val: UInt256) -> Self {
        Self(value: .primitive(.u256(val)), context: ())
    }
    
    public static func i256(_ val: Int256) -> Self {
        Self(value: .primitive(.i256(val)), context: ())
    }
    
    public static func bytes(_ val: Data) -> Self {
        Self(value: .primitive(.bytes(val)), context: ())
    }
}

extension Value.Def {
    public func mapContext<NC>(with mapper: @escaping (C) throws -> NC) rethrows -> Value<NC>.Def {
        switch self {
        case .primitive(let p): return try .primitive(p.mapContext(with: mapper))
        case .bitSequence(let seq): return .bitSequence(seq)
        case .sequence(let seq): return try .sequence(seq.map { try $0.mapContext(with: mapper) })
        case .map(let map):
            return try .map(
                Dictionary(uniqueKeysWithValues: map.map { try ($0.key, $0.value.mapContext(with: mapper)) })
            )
        case .variant(let v): return try .variant(v.mapContext(with: mapper))
        }
    }
}

extension Value.Primitive {
    public func mapContext<NC>(with mapper: @escaping (C) throws -> NC) rethrows -> Value<NC>.Primitive {
        switch self {
        case .bool(let v): return .bool(v)
        case .char(let v): return .char(v)
        case .string(let v): return .string(v)
        case .u256(let v): return .u256(v)
        case .i256(let v): return .i256(v)
        case .bytes(let v): return .bytes(v)
        }
    }
}

extension Value.Variant {
    public var name: String {
        switch self {
        case .sequence(name: let n, values: _): return n
        case .map(name: let n, fields: _): return n
        }
    }
    
    public var fields: [String: Value<C>]? {
        switch self {
        case .map(name: _, fields: let f): return f
        default: return nil
        }
    }
    
    public var values: [Value<C>] {
        switch self {
        case .map(name: _, fields: let f): return Array(f.values)
        case .sequence(name: _, values: let v): return v
        }
    }
    
    public func mapContext<NC>(with mapper: @escaping (C) throws -> NC) rethrows -> Value<NC>.Variant {
        switch self {
        case .sequence(name: let n, values: let vals):
            return try .sequence(name: n, values: vals.map { try $0.mapContext(with: mapper) })
        case .map(name: let n, fields: let map):
            return try .map(
                name: n,
                fields: Dictionary(
                    uniqueKeysWithValues: map.map { try ($0.key, $0.value.mapContext(with: mapper)) }
                )
            )
        }
    }
}

extension Value: Equatable where C: Equatable {}
extension Value.Def: Equatable where C: Equatable {}
extension Value.Variant: Equatable where C: Equatable {}

extension Value: Hashable where C: Hashable {}
extension Value.Def: Hashable where C: Hashable {}
extension Value.Variant: Hashable where C: Hashable {}
