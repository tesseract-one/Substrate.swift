//
//  AccountData.swift
//  
//
//  Created by Yehor Popovych on 10/8/20.
//

import Foundation
import ScaleCodec

public struct AccountData: Equatable, Hashable {
    public let fee: BigUInt
    public let reserved: BigUInt
    public let miscFrozen: BigUInt
    public let feeFrozen: BigUInt
}

extension AccountData: ScaleCodable {
    public init(from decoder: ScaleDecoder) throws {
        fee = try decoder.decode(.b128)
        reserved = try decoder.decode(.b128)
        miscFrozen = try decoder.decode(.b128)
        feeFrozen = try decoder.decode(.b128)
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder
            .encode(b128: fee).encode(b128: reserved)
            .encode(b128: miscFrozen).encode(b128: feeFrozen)
    }
}

extension AccountData: ScaleRegistryCodable {}
