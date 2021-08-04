//
//  RpcGrandpaApi.swift
//  
//
//  Created by Yehor Popovych on 04.08.2021.
//

import Foundation

public struct SubstrateRpcGrandpaApi<S: SubstrateProtocol>: SubstrateRpcApi where S.R: Grandpa {
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func proveFinality(
        begin: S.R.THash, end: S.R.THash,
        authoritiesSetId: UInt64?,
        timeout: TimeInterval? = nil,
        cb: @escaping SRpcApiCallback<Optional<EncodedFinalityProofs>>
    ) {
        substrate.client.call(
            method: "grandpa_proveFinality",
            params: RpcCallParams(begin, end, authoritiesSetId),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<Optional<EncodedFinalityProofs>>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func roundState(
        timeout: TimeInterval? = nil,
        cb: @escaping SRpcApiCallback<ReportedRoundStates<S.R.TKeys.TGrandpa.TPublic>>
    ) {
        substrate.client.call(
            method: "grandpa_roundState",
            params: RpcCallParams(),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<ReportedRoundStates<S.R.TKeys.TGrandpa.TPublic>>) in
            let result = res
                .mapError(SubstrateRpcApiError.rpc)
                .map { $0.changeSs58Format(new: self.substrate.properties.ss58Format) }
            cb(result)
        }
    }
}

extension SubstrateRpcGrandpaApi where S.C: SubscribableRpcClient {
    public func subscribeJustifications(
        timeout: TimeInterval? = nil,
        cb: @escaping SRpcApiCallback<JustificationNotification>
    ) -> RpcSubscription {
        substrate.client.subscribe(
            method: "grandpa_subscribeJustifications",
            params: RpcCallParams(),
            unsubscribe: "grandpa_unsubscribeJustifications"
        ) { (res: Result<JustificationNotification, RpcClientError>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
}


extension SubstrateRpcApiRegistry where S.R: Grandpa {
    public var state: SubstrateRpcGrandpaApi<S> { getRpcApi(SubstrateRpcGrandpaApi<S>.self) }
}

public typealias EncodedFinalityProofs = Data
public typealias JustificationNotification = Data

public struct ReportedRoundStates<AuthorityId: PublicKey & Hashable>: Decodable {
    public let setId: UInt32
    public let best: RoundState<AuthorityId>
    public let background: Array<RoundState<AuthorityId>>
    
    public func changeSs58Format(new: Ss58AddressFormat) -> Self {
        return Self(
            setId: setId,
            best: best.changeSs58Format(new: new),
            background: background.map { $0.changeSs58Format(new: new) }
        )
    }
}

public struct RoundState<AuthorityId: PublicKey & Hashable>: Decodable {
    public let round: UInt32
    public let totalWeight: UInt32
    public let thresholdWeight: UInt32
    public let prevotes: PrecommitsAndPrevotes<AuthorityId>
    public let precommits: PrecommitsAndPrevotes<AuthorityId>
    
    public func changeSs58Format(new: Ss58AddressFormat) -> Self {
        return Self(
            round: round, totalWeight: totalWeight, thresholdWeight: thresholdWeight,
            prevotes: prevotes.changeSs58Format(new: new),
            precommits: precommits.changeSs58Format(new: new)
        )
    }
}

public struct PrecommitsAndPrevotes<AuthorityId: PublicKey & Hashable>: Decodable {
    public let currentWeight: UInt32
    public let missing: Set<AuthorityId>
    
    public init(currentWeight: UInt32, missing: Set<AuthorityId>) {
        self.currentWeight = currentWeight
        self.missing = missing
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        currentWeight = try container.decode(UInt32.self, forKey: .currentWeight)
        let missingData = try container.decode(Array<Data>.self, forKey: .missing)
        missing = try Set(missingData.map { try AuthorityId(bytes: $0, format: .substrate) })
    }
    
    public func changeSs58Format(new: Ss58AddressFormat) -> Self {
        let nmiss = missing.map { try! AuthorityId(bytes: $0.bytes, format: new) }
        return Self(currentWeight: currentWeight, missing: Set(nmiss))
    }
    
    private enum Keys: String, CodingKey {
        case currentWeight
        case missing
    }
}
