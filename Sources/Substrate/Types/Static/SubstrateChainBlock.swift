//
//  SubstrateChainBlock.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ContextCodable
import Tuples

public typealias Justification = Tuple2<ConsensusEnngineId, Data>

public struct SubstrateChainBlock<B: StaticBlock>: StaticChainBlock {
    public typealias TBlock = B
    
    public let block: TBlock
    public let justifications: [Justification]?
    
    enum CodingKeys: CodingKey {
        case block
        case justifications
    }
    
    public init(from decoder: Decoder, runtime: Runtime) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        block = try container.decode(TBlock.self, forKey: .block, context: .init(runtime: runtime))
        justifications = try container.decode(Optional<[Justification]>.self, forKey: .justifications)
    }
}
