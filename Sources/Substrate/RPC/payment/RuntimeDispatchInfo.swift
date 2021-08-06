//
//  RuntimeDispatchInfo.swift
//  
//
//  Created by Yehor Popovych on 06.08.2021.
//

import Foundation

public struct RuntimeDispatchInfo<Balance: Decodable, Weight: WeightProtocol>: Decodable {
    public let weight: Weight
    public let clazz: DispatchInfo<Weight>.Class
    public let partialFee: Balance
    
    enum CodingKeys: String, CodingKey {
        case clazz = "class"
        case partialFee
        case weight
    }
}
