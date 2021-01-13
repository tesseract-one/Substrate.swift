//
//  BalancesEvents.swift
//  
//
//  Created by Yehor Popovych on 1/12/21.
//

import Foundation
import ScaleCodec

public struct BalancesTransferEvent<B: Balances> {
    /// Account balance was transfered from.
    public let from: B.TAccountId
    /// Account balance was transfered to.
    public let to: B.TAccountId
    /// Amount of balance that was transfered.
    public let amount: B.TBalance
    // Store dynamic types from registry
    private let types: (from: DType, to: DType, amount: DType)
}

extension BalancesTransferEvent: Event {
    public typealias Module = BalancesModule<B>
    
    public static var EVENT: String { "Transfer" }
    
    public init(decodingDataFrom decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        from = try B.TAccountId(from: decoder, registry: registry)
        to = try B.TAccountId(from: decoder, registry: registry)
        amount = try B.TBalance(from: decoder, registry: registry)
        let accIdType = try registry.type(of: B.TAccountId.self)
        let balType = try registry.type(of: B.TBalance.self)
        types = (from: accIdType, to: accIdType, amount: balType)
    }
    
    public var data: DValue {
        .collection(values: [
            .native(type: types.from, value: from),
            .native(type: types.to, value: to),
            .native(type: types.amount, value: amount)
        ])
    }
}
