//
//  BalancesCalls.swift
//  
//
//  Created by Yehor Popovych on 1/12/21.
//

import Foundation
import ScaleCodec

public struct TransferCall<B: Balances> {
    /// Destination of the transfer.
    public let to: B.TAddress
    /// Amount to transfer.
    public let amount: B.TBalance
}

extension TransferCall: Call {
    public typealias Module = BalancesModule<B>
    
    public static var FUNCTION: String { "Transfer" }
    
    public init(decodingParamsFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        to = try B.TAddress(from: decoder, registry: registry)
        amount = try decoder.decode(.compact)
    }
    
    public var params: [ScaleDynamicCodable] { [to, SCompact(amount)] }
}
