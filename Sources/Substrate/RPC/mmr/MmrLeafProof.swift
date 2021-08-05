//
//  MmrLeafProof.swift
//  
//
//  Created by Yehor Popovych on 05.08.2021.
//

import Foundation

public struct MmrLeafProof<BH: Hash>: Decodable {
    public let blockHash: BH
    public let leaf: Data
    public let proof: Data
}
