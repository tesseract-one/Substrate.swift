//
//  ContractResult.swift
//  
//
//  Created by Yehor Popovych on 05.08.2021.
//

import Foundation

public struct ContractResult<T: Decodable>: Decodable {
    public let gasConsumed: UInt64
    public let gasRequired: UInt64
    public let debugMessage: Data
    public let result: T
}
