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
    func asValue() throws -> Value<Void>
}

public typealias ValueConvertible = ValueInitializable & ValueRepresentable

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
    
    func asValue() throws -> Value<Void> {
        Self.min >= 0 ? .u256(UInt256(self)) : .i256(Int256(self))
    }
}

extension UInt8: ValueConvertible {}
extension UInt16: ValueConvertible {}
extension UInt32: ValueConvertible {}
extension UInt64: ValueConvertible {}
extension DoubleWidth: ValueConvertible {}
extension Int8: ValueConvertible {}
extension Int16: ValueConvertible {}
extension Int32: ValueConvertible {}
extension Int64: ValueConvertible {}

extension Value: ValueInitializable where C == Void {
    public init<C>(value: Value<C>) throws {
        self = value.mapContext(with: { _ in })
    }
}

extension Value: ValueRepresentable {
    public func asValue() throws -> Value<Void> {
        self.mapContext(with: { _ in })
    }
}
