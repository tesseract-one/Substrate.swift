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
        /// An unsigned integer.
        case uint(UInt256)
        /// A signed integer
        case int(Int256)
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

public extension Value {
    var map: [String: Self]? {
        switch value {
        case .map(let val): return val
        default: return nil
        }
    }
    
    var sequence: [Self]? {
        switch value {
        case .sequence(let val): return val
        case .map(let val): return Array(val.values)
        default: return nil
        }
    }
    
    var variant: Variant? {
        switch value {
        case .variant(let v): return v
        default: return nil
        }
    }
    
    var bitSequence: BitSequence? {
        switch value {
        case .bitSequence(let seq): return seq
        default: return nil
        }
    }
    
    var bool: Bool? {
        switch value {
        case .primitive(.bool(let b)): return b
        default: return nil
        }
    }
    
    var char: Character? {
        switch value {
        case .primitive(.char(let c)): return c
        default: return nil
        }
    }
    
    var string: String? {
        switch value {
        case .primitive(.string(let s)): return s
        default: return nil
        }
    }
    
    var uint: UInt256? {
        switch value {
        case .primitive(.uint(let u)): return u
        case .primitive(.int(let i)): return UInt256(exactly: i)
        default: return nil
        }
    }
    
    var int: Int256? {
        switch value {
        case .primitive(.int(let i)): return i
        case .primitive(.uint(let u)): return Int256(exactly: u)
        default: return nil
        }
    }
    
    var bytes: Data? {
        switch value {
        case .primitive(.bytes(let b)): return b
        case .sequence(let vals):
            let arr = vals.compactMap { $0.uint.flatMap { UInt8(exactly: $0) } }
            guard arr.count == vals.count else { return nil }
            return Data(arr)
        default: return nil
        }
    }
    
    func removingContext() -> Value<()> {
        mapContext { _ in }
    }
    
    func mapContext<NC>(with mapper: (C) throws -> NC) rethrows -> Value<NC> {
        try Value<NC>(value: value.mapContext(with: mapper), context: mapper(context))
    }
    
    func flatten() -> Self {
        switch self.value {
        case .sequence(let vals):
            if vals.count == 1 { return vals[0].flatten() }
            return self
        default: return self
        }
    }
    
    subscript(_ key: String) -> Value<C>? {
        switch value {
        case .map(let dict): return dict[key]
        case .sequence(let arr):
            guard var index = Int(key) else { return nil }
            index = index >= 0 ? index : arr.endIndex + index
            return arr.indices.contains(index) ? arr[index] : nil
        default: return nil
        }
    }
    
    subscript(_ index: Int) -> Value<C>? {
        guard case .sequence(let arr) = value else {
            return nil
        }
        let index = index >= 0 ? index : arr.endIndex + index
        return arr.indices.contains(index) ? arr[index] : nil
    }
}

public extension Value {
    static func map(_ map: [String: Value<C>], _ context: C) -> Self {
        Self(value: .map(map), context: context)
    }
    
    static func sequence<S: Sequence>(_ seq: S, _ context: C) -> Self
        where S.Element == Value<C>
    {
        Self(value: .sequence(Array(seq)), context: context)
    }
    
    static func variant<S: Sequence>(name: String, fields: S, _ context: C) -> Self
        where S.Element == (key: String, value: Value<C>)
    {
        let dict = Dictionary(uniqueKeysWithValues: fields.map{($0, $1)})
        return Self(value: .variant(.map(name: name,
                                         fields: dict)),
                    context: context)
    }
    
    static func variant<S: Sequence>(name: String, values: S, _ context: C) -> Self
        where S.Element == Value<C>
    {
        Self(value: .variant(.sequence(name: name, values: Array(values))),
             context: context)
    }
    
    static func bits(_ seq: BitSequence, _ context: C) -> Self {
        Self(value: .bitSequence(seq), context: context)
    }
    
    static func bits<S: Sequence>(array: S, _ context: C) -> Self where S.Element == Bool {
        .bits(BitSequence(array), context)
    }
    
    static func bool(_ val: Bool, _ context: C) -> Self {
        Self(value: .primitive(.bool(val)), context: context)
    }
    
    static func char(_ val: Character, _ context: C) -> Self {
        Self(value: .primitive(.char(val)), context: context)
    }
    
    static func string(_ val: String, _ context: C) -> Self {
        Self(value: .primitive(.string(val)), context: context)
    }
    
    static func uint(_ val: UInt256, _ context: C) -> Self {
        Self(value: .primitive(.uint(val)), context: context)
    }
    
    static func int(_ val: Int256, _ context: C) -> Self {
        Self(value: .primitive(.int(val)), context: context)
    }
    
    static func bytes(_ val: Data, _ context: C) -> Self {
        Self(value: .primitive(.bytes(val)), context: context)
    }
    
    static func bytes<S: Sequence>(array val: S, _ context: C) -> Self where S.Element == UInt8 {
        .bytes(Data(val), context)
    }
    
    static func `nil`(_ context: C) -> Self {
        Self(value: .sequence([]), context: context)
    }
}

public extension Value where C == Void {
    static func map<S: Sequence>(_ seq: S) -> Self
        where S.Element == (key: String, value: VoidValueRepresentable)
    {
        .map(Dictionary(uniqueKeysWithValues: seq.map{($0.key, $0.value.asValue())}), ())
    }
    
    static func sequence<S: Sequence>(_ seq: S) -> Self
        where S.Element == VoidValueRepresentable
    {
        .sequence(seq.map{$0.asValue()}, ())
    }

    static func variant<S: Sequence>(name: String, fields: S) -> Self
        where S.Element == (key: String, value: any VoidValueRepresentable)
    {
        .variant(name: name, fields: fields.map { ($0.key, $0.value.asValue()) }, ())
    }
    
    static func variant<S: Sequence>(name: String, values: S) -> Self
        where S.Element == VoidValueRepresentable
    {
        .variant(name: name, values: values.map{$0.asValue()}, ())
    }
    
    static func bits(_ seq: BitSequence) -> Self {
        .bits(seq, ())
    }
    
    static func bits<S: Sequence>(array: S) -> Self where S.Element == Bool {
        .bits(array: array, ())
    }
    
    static func bool(_ val: Bool) -> Self { .bool(val, ()) }
    static func char(_ val: Character) -> Self { .char(val, ()) }
    static func string(_ val: String) -> Self { .string(val, ()) }
    static func uint(_ val: UInt256) -> Self { .uint(val, ()) }
    static func int(_ val: Int256) -> Self { .int(val, ()) }
    static func bytes(_ val: Data) -> Self { .bytes(val, ()) }
    static func bytes<S: Sequence>(array val: S) -> Self where S.Element == UInt8 {
        .bytes(array: val, ())
    }
    static let `nil`: Self = .nil(())
}


extension Value.Def {
    public func mapContext<NC>(with mapper: (C) throws -> NC) rethrows -> Value<NC>.Def {
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
    public func mapContext<NC>(with mapper: (C) throws -> NC) rethrows -> Value<NC>.Primitive {
        switch self {
        case .bool(let v): return .bool(v)
        case .char(let v): return .char(v)
        case .string(let v): return .string(v)
        case .uint(let v): return .uint(v)
        case .int(let v): return .int(v)
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
    
    public func mapContext<NC>(with mapper: (C) throws -> NC) rethrows -> Value<NC>.Variant {
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

extension Value: CustomStringConvertible {
    public var description: String { value.description }
}

extension Value.Def: CustomStringConvertible {
    public var description: String {
        switch self {
        case .map(let fields):
            return "{\(fields.map{"\($0.key): \($0.value)"}.joined(separator: ", "))}"
        case .sequence(let values):
            return values.count == 0 ? "()" : values.description
        case .bitSequence(let bs): return bs.description
        case .primitive(let prim): return prim.description
        case .variant(let v): return v.description
        }
    }
}

extension Value.Variant: CustomStringConvertible {
    public var description: String {
        switch self {
        case .sequence(name: let name, values: let vals):
            return "\(name)\(vals.count == 0 ? "" : vals.description)"
        case .map(name: let name, fields: let fields):
            return "\(name){\(fields.map{"\($0.key): \($0.value)"}.joined(separator: ", "))}"
        }
    }
}

extension Value.Primitive: CustomStringConvertible {
    public var description: String {
        switch self {
        case .bool(let b): return b.description
        case .bytes(let data): return data.hex()
        case .char(let char): return String(char)
        case .string(let str): return str
        case .int(let int): return int.description
        case .uint(let uint): return uint.description
        }
    }
}

public protocol ValueRepresentable: ValidatableTypeDynamic {
    func asValue(runtime: any Runtime, type: TypeDefinition) throws -> Value<TypeDefinition>
}

public protocol VoidValueRepresentable {
    func asValue() -> Value<Void>
}
