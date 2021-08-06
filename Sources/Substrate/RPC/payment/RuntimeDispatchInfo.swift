//
//  RuntimeDispatchInfo.swift
//  
//
//  Created by Yehor Popovych on 06.08.2021.
//

import Foundation

public struct RuntimeDispatchInfo<Balance: Decodable & UnsignedInteger>: Decodable {
    public let weight: UInt64
    public let clazz: DispatchInfo.Class
    public let partialFee: Balance
    
    enum CodingKeys: String, CodingKey {
        case clazz = "class"
        case partialFee
        case weight
    }
}
