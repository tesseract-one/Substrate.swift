//
//  BeefyCommitment.swift
//  
//
//  Created by Yehor Popovych on 05.08.2021.
//

import Foundation
import ScaleCodec

public struct BeefyCommitment<Payload, BN, VId>: ScaleDynamicCodable
    where Payload: ScaleDynamicCodable, BN: BlockNumberProtocol, VId: ScaleDynamicCodable
{
    public let payload: Payload
    public let blockNumber: BN
    public let validatorSetId: VId
    
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        payload = try Payload(from: decoder, registry: registry)
        blockNumber = try BN(from: decoder, registry: registry)
        validatorSetId = try VId(from: decoder, registry: registry)
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try payload.encode(in: encoder, registry: registry)
        try blockNumber.encode(in: encoder, registry: registry)
        try validatorSetId.encode(in: encoder, registry: registry)
    }
}

public struct BeefySignedCommitment<Payload, BN, VId, Sig>: ScaleDynamicCodable
    where
        Payload: ScaleDynamicCodable, BN: BlockNumberProtocol,
        VId: ScaleDynamicCodable, Sig: Signature
{
    public let commitment: BeefyCommitment<Payload, BN, VId>
    public let signatures: Array<Optional<Sig>>
    
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        commitment = try BeefyCommitment<Payload, BN, VId>(from: decoder, registry: registry)
        signatures = try Array<Optional<Sig>>(from: decoder, registry: registry)
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try commitment.encode(in: encoder, registry: registry)
        try signatures.encode(in: encoder, registry: registry)
    }
}
