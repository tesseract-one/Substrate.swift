//
//  SyncState.swift
//  
//
//  Created by Yehor Popovych on 06.08.2021.
//

import Foundation

public struct SyncState<BN: BlockNumberProtocol>: Codable {
    public let startingBlock: BN
    public let currentBlock: BN
    public let highestBlock: Optional<BN>
    
    private enum CodingKeys: String, CodingKey {
        case startingBlock
        case currentBlock
        case highestBlock
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var data = try container.decode(Data.self, forKey: .startingBlock)
        startingBlock = try BN(jsonData: data)
        data = try container.decode(Data.self, forKey: .currentBlock)
        currentBlock = try BN(jsonData: data)
        if let data = try container.decode(Optional<Data>.self, forKey: .highestBlock) {
            highestBlock = try BN(jsonData: data)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(startingBlock.jsonData, forKey: .startingBlock)
        try container.encode(currentBlock.jsonData, forKey: .currentBlock)
        try container.encode(highestBlock.map { $0.jsonData }, forKey: .highestBlock)
    }
}
