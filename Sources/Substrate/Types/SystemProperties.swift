//
//  SystemProperties.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import SubstratePrimitives

public struct SystemProperties: Decodable {
    /// The address format
    public let ss58Format: Ss58AddressFormat
    /// The number of digits after the decimal point in the native token
    public let tokenDecimals: UInt8
    /// The symbol of the native token
    public let tokenSymbol: String
}
