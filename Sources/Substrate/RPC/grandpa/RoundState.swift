//
//  RoundState.swift
//  
//
//  Created by Yehor Popovych on 05.08.2021.
//

import Foundation

public struct RoundState<AuthorityId: PublicKey & Hashable>: Decodable {
    public let round: UInt32
    public let totalWeight: UInt32
    public let thresholdWeight: UInt32
    public let prevotes: PrecommitsAndPrevotes<AuthorityId>
    public let precommits: PrecommitsAndPrevotes<AuthorityId>
}
