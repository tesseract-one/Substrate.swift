//
//  RentProjection.swift
//  
//
//  Created by Yehor Popovych on 05.08.2021.
//

import Foundation

public enum RentProjection<BN: BlockNumberProtocol>: Equatable, Decodable {
    case eviction(at: BN)
    case noEviction
    
    public init(from decoder: Decoder) throws {
        let container1 = try decoder.singleValueContainer()
        if let simple = try? container1.decode(String.self) {
            guard simple == "NoEviction" else {
                throw DecodingError.dataCorruptedError(in: container1, debugDescription: "Unknown case \(simple)")
            }
            self = .noEviction
        } else {
            let container2 = try decoder.container(keyedBy: CodableComplexKey<Self>.self)
            guard let key = container2.allKeys.first else {
                throw DecodingError.dataCorruptedError(in: container1, debugDescription: "Empty case object")
            }
            guard key.stringValue == "EvictionAt" else {
                throw DecodingError.dataCorruptedError(forKey: key, in: container2, debugDescription: "Unknow enum case")
            }
            let data = try container2.decode(Data.self, forKey: key)
            self = try .eviction(at: BN(jsonData: data))
        }
    }
}
