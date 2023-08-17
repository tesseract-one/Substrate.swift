//
//  BigIntegers.swift
//  
//
//  Created by Yehor Popovych on 11/08/2023.
//

import Foundation
import ScaleCodec
@_exported import struct Numberick.NBKDoubleWidth

@_exported import typealias Numberick.Int128
@_exported import typealias Numberick.Int256
@_exported import typealias Numberick.Int512
@_exported import typealias Numberick.Int1024

@_exported import typealias Numberick.UInt128
@_exported import typealias Numberick.UInt256
@_exported import typealias Numberick.UInt512
@_exported import typealias Numberick.UInt1024

extension NBKDoubleWidth: CompactCodable where Self: UnsignedInteger {}
extension NBKDoubleWidth: CompactConvertible where Self: UnsignedInteger {}

extension NBKDoubleWidth: FixedDataCodable, DataConvertible, SizeCalculable {}
