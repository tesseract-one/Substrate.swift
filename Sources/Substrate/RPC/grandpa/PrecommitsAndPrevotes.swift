//
//  PrecommitsAndPrevotes.swift
//  
//
//  Created by Yehor Popovych on 05.08.2021.
//

import Foundation

public struct PrecommitsAndPrevotes<AuthorityId: PublicKey & Hashable>: Decodable {
    public let currentWeight: UInt32
    public let missing: Set<AuthorityId>
    
    public init(currentWeight: UInt32, missing: Set<AuthorityId>) {
        self.currentWeight = currentWeight
        self.missing = missing
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        currentWeight = try container.decode(UInt32.self, forKey: .currentWeight)
        let missingData = try container.decode(Array<Data>.self, forKey: .missing)
        let format = decoder.typeRegistry?.ss58AddressFormat ?? .substrate
        missing = try Set(missingData.map { try AuthorityId(bytes: $0, format: format) })
    }
    
    private enum Keys: String, CodingKey {
        case currentWeight
        case missing
    }
}
