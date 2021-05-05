//
//  SignedBlock.swift
//  
//
//  Created by Ostap Danylovych on 04.05.2021.
//

import Foundation

public struct SignedBlock<Block: Codable> {
    public let block: Block
    public let justification: Justification?
    
    enum CodingKeys: String, CodingKey {
        case block
        case justification = "justifications"
    }
}

extension SignedBlock: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        block = try container.decode(Block.self, forKey: .block)
        justification = try container.decode(Justification.self, forKey: .justification)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(justification, forKey: .justification)
    }
}

public struct Block<Header: Codable, Extrinsic: Codable> {
    public let header: Header
    public let extrinsics: [Extrinsic]
    
    enum CodingKeys: String, CodingKey {
        case header
        case extrinsics
    }
}

extension Block: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        header = try container.decode(Header.self, forKey: .header)
        extrinsics = try container.decode([Extrinsic].self, forKey: .extrinsics)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(header, forKey: .header)
        try container.encode(extrinsics, forKey: .extrinsics)
    }
}

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
