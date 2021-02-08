//
//  HelperProtocols.swift
//  
//
//  Created by Yehor Popovych on 2/8/21.
//

import Foundation
import ScaleCodec

public protocol BlockNumberProtocol: ScaleDynamicCodable, SDefault, Codable {
    static var firstBlock: Self { get }
}

extension UnsignedInteger {
    public static var firstBlock: Self { 0 }
}

//extension ScaleFixedUnsignedInteger {
//    public static var firstBlock: Self { 0 }
//}

extension UInt32: BlockNumberProtocol {}
extension UInt64: BlockNumberProtocol {}
//extension SUInt128: BlockNumberProtocol {}
//extension SUInt256: BlockNumberProtocol {}
//extension SUInt512: BlockNumberProtocol {}
