//
//  RpcPaymentApi.swift
//  
//
//  Created by Yehor Popovych on 04.08.2021.
//

import Foundation

public struct SubstrateRpcPaymentApi<S: SubstrateProtocol>: SubstrateRpcApi where S.R: Balances {
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func queryFeeDetails<E: ExtrinsicProtocol>(
        extrinsic: E, at hash: S.R.THash?,
        timeout: TimeInterval? = nil,
        cb: @escaping SRpcApiCallback<FeeDetails<S.R.TBalance>>
    ) {
        guard let data = _encode(value: extrinsic, cb) else { return }
        substrate.client.call(
            method: "payment_queryFeeDetails",
            params: RpcCallParams(data, hash),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<FeeDetails<S.R.TBalance>>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func queryInfo<E: ExtrinsicProtocol>(
        extrinsic: E, at hash: S.R.THash?,
        timeout: TimeInterval? = nil,
        cb: @escaping SRpcApiCallback<RuntimeDispatchInfo<S.R.TBalance>>
    ) {
        guard let data = _encode(value: extrinsic, cb) else { return }
        substrate.client.call(
            method: "payment_queryInfo",
            params: RpcCallParams(data, hash),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<RuntimeDispatchInfo<S.R.TBalance>>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
}

extension SubstrateRpcApiRegistry where S.R: Balances {
    public var payment: SubstrateRpcPaymentApi<S> { getRpcApi(SubstrateRpcPaymentApi<S>.self) }
}

public struct FeeDetails<Balance: Decodable & UnsignedInteger>: Decodable {
    public let inclusionFee: Optional<InclusionFee<Balance>>
}

public struct InclusionFee<Balance: Decodable & UnsignedInteger>: Decodable {
    public let baseFee: Balance
    public let lenFee: Balance
    public let adjustedWeightFee: Balance
}

public struct RuntimeDispatchInfo<Balance: Decodable & UnsignedInteger>: Decodable {
    public let weight: UInt64
    public let clazz: DispatchInfo.Class
    public let partialFee: Balance
    
    enum CodingKeys: String, CodingKey {
        case clazz = "class"
        case partialFee
        case weight
    }
}
