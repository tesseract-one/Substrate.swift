//
//  Default.swift
//  
//
//  Created by Yehor Popovych on 12.05.2023.
//

import Foundation
import ScaleCodec
import Numberick

public protocol Default {
    static var `default`: Self { get }
}

public extension BinaryInteger {
    static var `default`: Self { 0 }
}

extension Bool: Default {
    public static var `default`: Self { false }
}

extension String: Default {
    public static var `default`: Self { "" }
}

extension Character: Default {
    public static var `default`: Character { Character("\0") }
}

extension Compact: Default where T: Default {
    public static var `default`: Compact<T> { Compact(.default) }
}

extension Data: Default {
    public static var `default`: Data { Data() }
}

extension Array: Default {
    public static var `default`: Self { Self() }
}

extension Dictionary: Default {
    public static var `default`: Self { Self() }
}

extension UInt8: Default {}
extension UInt16: Default {}
extension UInt32: Default {}
extension UInt64: Default {}
extension Int8: Default {}
extension Int16: Default {}
extension Int32: Default {}
extension Int64: Default {}
extension NBKDoubleWidth: Default {}
