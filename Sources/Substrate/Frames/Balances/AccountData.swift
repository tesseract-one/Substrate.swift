//
//  AccountData.swift
//  
//
//  Created by Yehor Popovych on 10/8/20.
//

import Foundation
import ScaleCodec

public struct AccountData<Balance: ScaleDynamicCodable> {
    public let free: Balance
    public let reserved: Balance
    public let miscFrozen: Balance
    public let feeFrozen: Balance
}

extension AccountData: ScaleDynamicCodable {
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        free = try Balance(from: decoder, registry: registry)
        reserved = try Balance(from: decoder, registry: registry)
        miscFrozen = try Balance(from: decoder, registry: registry)
        feeFrozen = try Balance(from: decoder, registry: registry)
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try free.encode(in: encoder, registry: registry)
        try reserved.encode(in: encoder, registry: registry)
        try miscFrozen.encode(in: encoder, registry: registry)
        try feeFrozen.encode(in: encoder, registry: registry)
    }
}
