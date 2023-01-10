//
//  BlockNumber.swift
//  
//
//  Created by Yehor Popovych on 2/8/21.
//

import Foundation
import ScaleCodec
import BigInt

public protocol AnyBlockNumber: UnsignedInteger, DataConvertible {
    static var firstBlock: Self { get }
}

extension UnsignedInteger {
    public static var firstBlock: Self { 0 }
}

extension UInt32: AnyBlockNumber {}
extension UInt64: AnyBlockNumber {}
extension DoubleWidth: AnyBlockNumber where Base: UnsignedInteger {}
