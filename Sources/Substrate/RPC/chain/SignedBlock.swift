//
//  SignedBlock.swift
//  
//
//  Created by Ostap Danylovych on 04.05.2021.
//

import Foundation

public struct SignedBlock<Block> {
    public let block: Block
    public let justification: Justification?
    
    enum CodingKeys: String, CodingKey {
        case block
        case justification = "justifications"
    }
}

extension SignedBlock: Codable where Block: Codable {
//    public init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        block = try container.decode(Block.self, forKey: .block)
//        justification = try container.decode(Justification.self, forKey: .block)
//    }
//    
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(block, forKey: .block)
//        try container.encode(justification, forKey: .justification)
//    }
}

public struct Block<Header, Extrinsic> {
    public let header: Header
    public let extrinsics: [Extrinsic]
}

extension Block: Codable where Header: Codable, Extrinsic: Codable {}

public struct Justification {
    public let data: Data
}

extension Justification: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        data = try container.decode(Data.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }
}
