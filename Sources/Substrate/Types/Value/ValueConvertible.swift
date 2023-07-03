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

public protocol ValueArrayRepresentable {
    func asValueArray() throws -> [AnyValue]
}

public protocol ValueMapRepresentable {
    func asValueMap() throws -> [String: AnyValue]
}

public extension ValueArrayRepresentable {
    func asValue() throws -> AnyValue { try .sequence(asValueArray()) }
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

extension Bool: ValueRepresentable {
    public func asValue() throws -> AnyValue { .bool(self) }
}

extension String: ValueRepresentable {
    public func asValue() throws -> AnyValue { .string(self) }
}

extension Data: ValueRepresentable {
    public func asValue() throws -> AnyValue { .bytes(self) }
}

public extension Sequence where Element: ValueRepresentable {
    func asValueArray() throws -> [AnyValue] {
        try map { try $0.asValue() }
    }
}

extension Array: ValueRepresentable where Element: ValueRepresentable {}
extension Array: ValueArrayRepresentable where Element: ValueRepresentable {}

extension KeyValuePairs: ValueRepresentable where Key: StringProtocol, Value: ValueRepresentable {}
extension KeyValuePairs: ValueMapRepresentable where Key: StringProtocol, Value: ValueRepresentable {
    public func asValueMap() throws -> [String: AnyValue] {
        try Dictionary(uniqueKeysWithValues: map { try (String($0.key), $0.value.asValue()) })
    }
}

extension Dictionary: ValueRepresentable where Key: StringProtocol, Value: ValueRepresentable {}
extension Dictionary: ValueMapRepresentable where Key: StringProtocol, Value: ValueRepresentable {
    public func asValueMap() throws -> [String: AnyValue] {
        try Dictionary<_, _>(uniqueKeysWithValues: map { try (String($0.key), $0.value.asValue()) })
    }
}
