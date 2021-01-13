//
//  Header.swift
//  
//
//  Created by Yehor Popovych on 1/12/21.
//

import Foundation
import ScaleCodec

public struct Header<Number: ScaleDynamicCodable, Hash: ScaleFixedData>: ScaleDynamicCodable {
    public let parentHash: Hash
    public let number: Number
    public let stateRoot: Hash
    public let extrinsicRoot: Hash
    public let digest: Digest<Hash>
    
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        parentHash = try Hash(from: decoder, registry: registry)
        number = try Number(from: decoder, registry: registry)
        stateRoot = try Hash(from: decoder, registry: registry)
        extrinsicRoot = try Hash(from: decoder, registry: registry)
        digest = try Digest<Hash>(from: decoder, registry: registry)
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try parentHash.encode(in: encoder, registry: registry)
        try number.encode(in: encoder, registry: registry)
        try stateRoot.encode(in: encoder, registry: registry)
        try extrinsicRoot.encode(in: encoder, registry: registry)
        try digest.encode(in: encoder, registry: registry)
    }
}
