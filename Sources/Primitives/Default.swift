//
//  Default.swift
//  
//
//  Created by Yehor Popovych on 2/8/21.
//

import Foundation
import ScaleCodec

public protocol SDefault {
    static func `default`() -> Self
}

extension BinaryInteger {
    public static func `default`() -> Self { 0 }
}

extension UInt8: SDefault {}
extension UInt16: SDefault {}
extension UInt32: SDefault {}
extension UInt64: SDefault {}

extension Int8: SDefault {}
extension Int16: SDefault {}
extension Int32: SDefault {}
extension Int64: SDefault {}

extension BigInt: SDefault {}
extension BigUInt: SDefault {}

extension ScaleFixedUnsignedInteger {
    public static func `default`() -> Self { try! Self(bigUInt: .default()) }
}

extension SUInt128: SDefault {}
extension SUInt256: SDefault {}
extension SUInt512: SDefault {}
