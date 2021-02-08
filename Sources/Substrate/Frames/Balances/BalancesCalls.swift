//
//  BalancesCalls.swift
//  
//
//  Created by Yehor Popovych on 1/12/21.
//

import Foundation
import ScaleCodec

public struct BalancesTransferCall<B: Balances> {
    /// Destination of the transfer.
    public let to: B.TAddress
    /// Amount to transfer.
    public let amount: B.TBalance
}

extension BalancesTransferCall: Call {
    public typealias Module = BalancesModule<B>
    
    public static var FUNCTION: String { "transfer" }
    
    public init(decodingParamsFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        to = try B.TAddress(from: decoder, registry: registry)
        amount = try decoder.decode(.compact)
    }
    
    public func encode(paramsIn encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try to.encode(in: encoder, registry: registry)
        try amount.encode(in: encoder, registry: registry)
    }
}
