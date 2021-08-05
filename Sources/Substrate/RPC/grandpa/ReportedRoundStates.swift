//
//  ReportedRoundStates.swift
//  
//
//  Created by Yehor Popovych on 05.08.2021.
//

import Foundation

public struct ReportedRoundStates<AuthorityId: PublicKey & Hashable>: Decodable {
    public let setId: UInt32
    public let best: RoundState<AuthorityId>
    public let background: Array<RoundState<AuthorityId>>
}
