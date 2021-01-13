//
//  Header.swift
//  
//
//  Created by Yehor Popovych on 1/12/21.
//

import Foundation
import ScaleCodec

public struct Header<Number: ScaleDynamicCodable, H: Hash>: ScaleDynamicCodable {
    public let parentHash: H
    public let number: Number
    public let stateRoot: H
    public let extrinsicRoot: H
    public let digest: Digest<H>
    
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
