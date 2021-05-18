//
//  Header.swift
//  
//
//  Created by Yehor Popovych on 1/12/21.
//

import Foundation
import ScaleCodec

public struct Header<Number: BlockNumberProtocol, H: Hash> {
    public let parentHash: H
    public let number: Number
    public let stateRoot: H
    public let extrinsicRoot: H
    public let digest: Digest<H>
    
    enum CodingKeys: String, CodingKey {
        case parentHash
        case number
        case stateRoot
        case extrinsicRoot = "extrinsicsRoot"
        case digest
    }
}

extension Header: ScaleDynamicCodable {
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        parentHash = try decoder.decode()
        number = try Number(from: decoder, registry: registry)
        stateRoot = try decoder.decode()
        extrinsicRoot = try decoder.decode()
        digest = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try parentHash.encode(in: encoder, registry: registry)
        try number.encode(in: encoder, registry: registry)
        try stateRoot.encode(in: encoder, registry: registry)
        try extrinsicRoot.encode(in: encoder, registry: registry)
        try digest.encode(in: encoder, registry: registry)
    }
}

extension Header: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        parentHash = try container.decode(H.self, forKey: .parentHash)
        let numberData = try container.decode(Data.self, forKey: .number)
        number = try Number(jsonData: numberData)
        //number = try container.decode(Number.self, forKey: .number)
        stateRoot = try container.decode(H.self, forKey: .stateRoot)
        extrinsicRoot = try container.decode(H.self, forKey: .extrinsicRoot)
        digest = try container.decode(Digest<H>.self, forKey: .digest)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(parentHash, forKey: .parentHash)
        try container.encode(number.jsonData, forKey: .number)
        //try number.encode(toJson: container.superEncoder(forKey: .number))
        //try container.encode(number, forKey: .number)
        try container.encode(stateRoot, forKey: .stateRoot)
        try container.encode(extrinsicRoot, forKey: .extrinsicRoot)
        try container.encode(digest, forKey: .digest)
    }
}
