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
    
    public func queryFeeDetails(
        extrinsic: S.R.TExtrinsic, at hash: S.R.THash?,
        timeout: TimeInterval? = nil,
        _ cb: @escaping SRpcApiCallback<FeeDetails<S.R.TBalance>>
    ) {
        _encode(extrinsic)
            .pour(queue: substrate.client.responseQueue, error: cb)
            .onSuccess { data in
                self.substrate.client.call(
                    method: "payment_queryFeeDetails",
                    params: RpcCallParams(data, hash),
                    timeout: timeout ?? self.substrate.callTimeout
                ) { (res: RpcClientResult<FeeDetails<S.R.TBalance>>) in
                    cb(res.mapError(SubstrateRpcApiError.rpc))
                }
            }
    }
    
    public func queryInfo(
        extrinsic: S.R.TExtrinsic, at hash: S.R.THash?,
        timeout: TimeInterval? = nil,
        cb: @escaping SRpcApiCallback<RuntimeDispatchInfo<S.R.TBalance, S.R.TWeight>>
    ) {
        _encode(extrinsic)
            .pour(queue: substrate.client.responseQueue, error: cb)
            .onSuccess { data in
                self.substrate.client.call(
                    method: "payment_queryInfo",
                    params: RpcCallParams(data, hash),
                    timeout: timeout ?? self.substrate.callTimeout
                ) { (res: RpcClientResult<RuntimeDispatchInfo<S.R.TBalance, S.R.TWeight>>) in
                    cb(res.mapError(SubstrateRpcApiError.rpc))
                }
            }
        
    }
}

extension SubstrateRpcApiRegistry where S.R: Balances {
    public var payment: SubstrateRpcPaymentApi<S> { getRpcApi(SubstrateRpcPaymentApi<S>.self) }
}
