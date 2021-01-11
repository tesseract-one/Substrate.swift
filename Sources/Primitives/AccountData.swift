//
//  AccountData.swift
//  
//
//  Created by Yehor Popovych on 10/8/20.
//

import Foundation
import ScaleCodec

public struct AccountData<Balance: ScaleCodable & BinaryInteger> {
    public let free: Balance
    public let reserved: Balance
    public let miscFrozen: Balance
    public let feeFrozen: Balance
}

extension AccountData: ScaleCodable {
    public init(from decoder: ScaleDecoder) throws {
        free = try decoder.decode()
        reserved = try decoder.decode()
        miscFrozen = try decoder.decode()
        feeFrozen = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder
            .encode(free).encode(reserved)
            .encode(miscFrozen).encode(feeFrozen)
    }
}

extension AccountData: ScaleDynamicCodable {}
