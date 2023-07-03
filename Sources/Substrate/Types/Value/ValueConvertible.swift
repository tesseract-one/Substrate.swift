//
//  ValueConvertible.swift
//  
//
//  Created by Yehor Popovych on 17.01.2023.
//

import Foundation
import ScaleCodec

public protocol ValueInitializable {
    init<C>(value: Value<C>) throws
}

public protocol ValueRepresentable {
    func asValue() throws -> AnyValue
}

public typealias ValueConvertible = ValueInitializable & ValueRepresentable

public protocol ValueArrayInitializable {
    init<C>(values: [Value<C>]) throws
}

public protocol ValueArrayRepresentable {
    func asValueArray() throws -> [AnyValue]
}

public protocol ValueMapInitializable {
    init<C>(values: [String: Value<C>]) throws
}

public protocol ValueMapRepresentable {
    func asValueMap() throws -> [String: AnyValue]
}

public extension ValueArrayInitializable {
    init<C>(value: Value<C>) throws {
        switch value.value {
        case .sequence(let values): try self.init(values: values)
        default:
            throw ValueInitializableError.wrongValueType(got: value.value,
                                                         for: String(describing: Self.self))
        }
    }
}

public extension ValueArrayRepresentable {
    func asValue() throws -> AnyValue { try .sequence(asValueArray()) }
}

public extension ValueMapInitializable {
    init<C>(value: Value<C>) throws {
        switch value.value {
        case .map(let fields): try self.init(values: fields)
        default:
            throw ValueInitializableError.wrongValueType(got: value.value,
                                                         for: String(describing: Self.self))
        }
    }
}

public extension ValueMapRepresentable {
    func asValue() throws -> AnyValue { try .map(asValueMap()) }
}

public enum ValueInitializableError<C>: Error {
    case wrongValueType(got: Value<C>.Def, for: String)
    case wrongValuesCount(in: Value<C>.Def, expected: Int, for: String)
    case unknownVariant(name: String, in: Value<C>.Def, for: String)
    case integerOverflow(got: Int512, min: Int512, max: Int512)
}

public extension FixedWidthInteger {
    init<C>(value: Value<C>) throws {
        switch value.value {
        case .primitive(.u256(let uint)):
            guard uint <= Self.max else {
                throw ValueInitializableError<C>.integerOverflow(got: Int512(uint),
                                                                 min: Int512(Self.min),
                                                                 max: Int512(Self.max))
            }
            self.init(uint)
        case .primitive(.i256(let int)):
            guard int <= Self.max && int >= Self.min else {
                throw ValueInitializableError<C>.integerOverflow(got: Int512(int),
                                                                 min: Int512(Self.min),
                                                                 max: Int512(Self.max))
            }
            self.init(int)
        default:
            throw ValueInitializableError<C>.wrongValueType(got: value.value,
                                                            for: String(describing: Self.self))
        }
    }
    
    func asValue() throws -> AnyValue {
        Self.isSigned ?  .i256(Int256(self)) : .u256(UInt256(self))
    }
}

extension UInt8: ValueConvertible {}
extension UInt16: ValueConvertible {}
extension UInt32: ValueConvertible {}
extension UInt64: ValueConvertible {}
extension UInt: ValueConvertible {}
extension DoubleWidth: ValueConvertible {}
extension Int8: ValueConvertible {}
extension Int16: ValueConvertible {}
extension Int32: ValueConvertible {}
extension Int64: ValueConvertible {}
extension Int: ValueConvertible {}

extension Value: ValueInitializable where C == Void {
    public init<C2>(value: Value<C2>) throws {
        self = value.mapContext(with: { _ in })
    }
}

extension Value: ValueRepresentable {
    public func asValue() throws -> AnyValue {
        self.mapContext(with: { _ in })
    }
}

extension Bool: ValueConvertible {
    public init<C>(value: Value<C>) throws {
        guard let bool = value.bool else {
            throw ValueInitializableError.wrongValueType(got: value.value,
                                                         for: "Bool")
        }
        self = bool
    }
    
    public func asValue() throws -> AnyValue { .bool(self) }
}

extension String: ValueConvertible {
    public init<C>(value: Value<C>) throws {
        guard let string = value.string else {
            throw ValueInitializableError.wrongValueType(got: value.value,
                                                         for: "String")
        }
        self = string
    }
    
    public func asValue() throws -> AnyValue { .string(self) }
}

extension Data: ValueConvertible {
    public init<C>(value: Value<C>) throws {
        guard let data = value.bytes else {
            throw ValueInitializableError.wrongValueType(got: value.value,
                                                         for: "Data")
        }
        self = data
    }
    
    public func asValue() throws -> AnyValue { .bytes(self) }
}

extension Character: ValueConvertible {
    public init<C>(value: Value<C>) throws {
        guard let char = value.char else {
            throw ValueInitializableError.wrongValueType(got: value.value,
                                                         for: "Character")
        }
        self = char
    }
    
    public func asValue() throws -> AnyValue { .char(self) }
}

public extension Sequence where Element: ValueRepresentable {
    func asValueArray() throws -> [AnyValue] {
        try map { try $0.asValue() }
    }
}

extension Array: ValueInitializable where Element: ValueInitializable {}
extension Array: ValueArrayInitializable where Element: ValueInitializable {
    public init<C>(values: [Value<C>]) throws {
        self = try values.map { try Element(value: $0) }
    }
}
extension Array: ValueRepresentable where Element: ValueRepresentable {}
extension Array: ValueArrayRepresentable where Element: ValueRepresentable {}

extension Set: ValueInitializable where Element: ValueInitializable {}
extension Set: ValueArrayInitializable where Element: ValueInitializable {
    public init<C>(values: [Value<C>]) throws {
        self = try Set(values.map { try Element(value: $0) })
    }
}
extension Set: ValueRepresentable where Element: ValueRepresentable {}
extension Set: ValueArrayRepresentable where Element: ValueRepresentable {}

extension KeyValuePairs: ValueRepresentable where Key: StringProtocol, Value: ValueRepresentable {}
extension KeyValuePairs: ValueMapRepresentable where Key: StringProtocol, Value: ValueRepresentable {
    public func asValueMap() throws -> [String: AnyValue] {
        try Dictionary(uniqueKeysWithValues: map { try (String($0.key), $0.value.asValue()) })
    }
}

extension Dictionary: ValueInitializable where Key: StringProtocol, Value: ValueInitializable {}
extension Dictionary: ValueMapInitializable where Key: StringProtocol, Value: ValueInitializable {
    public init<C>(values: [String: DValue<C>]) throws {
        try self.init(uniqueKeysWithValues:
            values.map { try (Key(stringLiteral: $0), Value(value: $1)) }
        )
    }
}
extension Dictionary: ValueRepresentable where Key: StringProtocol, Value: ValueRepresentable {}
extension Dictionary: ValueMapRepresentable where Key: StringProtocol, Value: ValueRepresentable {
    public func asValueMap() throws -> [String: AnyValue] {
        try Dictionary<_, _>(uniqueKeysWithValues: map { try (String($0.key), $0.value.asValue()) })
    }
}
