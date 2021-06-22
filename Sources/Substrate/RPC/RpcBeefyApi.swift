//
//  RpcBeefyApi.swift
//  
//
//  Created by Ostap Danylovych on 03.05.2021.
//

import Foundation

public struct SubstrateRpcBeefyApi<S: SubstrateProtocol>: SubstrateRpcApi where S.R: BeefyApi {
    public weak var substrate: S!
    
    public typealias SBeefySignedCommitment = BeefySignedCommitment<
        S.R.TBeefyPayload, S.R.TBlockNumber, S.R.TBeefyValidatorSetId, S.R.TSignature
    >
    
    public init(substrate: S) {
        self.substrate = substrate
    }
}

extension SubstrateRpcBeefyApi where S.C: SubscribableRpcClient {
    public func subscribeJustifications(
        timeout: TimeInterval? = nil, _ cb: @escaping SRpcApiCallback<SBeefySignedCommitment>
    ) -> RpcSubscription {
        let registry = substrate.registry
        return substrate.client.subscribe(
            method: "beefy_subscribeJustifications",
            params: RpcCallParams(),
            unsubscribe: "beefy_unsubscribeJustifications"
        ) { (res: RpcClientResult<Data>) in
            let result = res.mapError(SubstrateRpcApiError.rpc).flatMap { data in
                Result {
                    try SBeefySignedCommitment(from: SCALE.default.decoder(data: data), registry: registry)
                }.mapError(SubstrateRpcApiError.from)
            }
            cb(result)
        }
    }
}

extension SubstrateRpcApiRegistry where S.R: BeefyApi {
    public var beefy: SubstrateRpcBeefyApi<S> { getRpcApi(SubstrateRpcBeefyApi<S>.self) }
}


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
