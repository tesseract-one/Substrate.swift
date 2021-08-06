//
//  PaymentFee.swift
//  
//
//  Created by Yehor Popovych on 06.08.2021.
//

import Foundation

public struct FeeDetails<Balance: Decodable>: Decodable {
    public let inclusionFee: Optional<InclusionFee<Balance>>
}

public struct InclusionFee<Balance: Decodable>: Decodable {
    public let baseFee: Balance
    public let lenFee: Balance
    public let adjustedWeightFee: Balance
}
