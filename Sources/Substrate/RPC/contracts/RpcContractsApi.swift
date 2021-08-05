//
//  RpcContractsApi.swift
//  
//
//  Created by Yehor Popovych on 03.08.2021.
//

import Foundation

public struct SubstrateRpcContractsApi<S: SubstrateProtocol>: SubstrateRpcApi where S.R: Contracts {
    public weak var substrate: S!
    
    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func call(_ call: ContractCallRequest<S.R.TAccountId, S.R.TBalance, S.R.TGas>,
                     at hash: S.R.THash?,
                     timeout: TimeInterval? = nil,
                     cb: @escaping SRpcApiCallback<ContractCallResult>) {
        substrate.client.call(
            method: "contracts_call",
            params: RpcCallParams(call, hash),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<ContractCallResult> ) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func call(origin: S.R.TAccountId, dest: S.R.TAccountId, value: S.R.TBalance,
                     gasLimit: S.R.TGas, inputData: Data,
                     at hash: S.R.THash?,
                     timeout: TimeInterval? = nil,
                     cb: @escaping SRpcApiCallback<ContractCallResult>) {
        let c = ContractCallRequest(
            origin: origin, dest: dest, value: value, gasLimit: gasLimit, inputData: inputData
        )
        self.call(c, at: hash, timeout: timeout, cb: cb)
    }
    
    public func getStorage(address: S.R.TAccountId,
                           key: Hash256, at hash: S.R.THash?,
                           timeout: TimeInterval? = nil,
                           cb: @escaping SRpcApiCallback<Optional<Data>>) {
        substrate.client.call(
            method: "contracts_getStorage",
            params: RpcCallParams(address.bytes, key, hash),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<Optional<Data>>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func getStorage<T: ScaleDynamicDecodable>(
        address: S.R.TAccountId,
        key: Hash256, at hash: S.R.THash?,
        timeout: TimeInterval? = nil,
        cb: @escaping SRpcApiCallback<Optional<T>>
    ) {
        getStorage(address: address, key: key, at: hash) { res in
            let result: SRpcApiResult<Optional<T>> = res
                .flatMap {
                    guard let data = $0 else { return .success(nil) }
                    return Result {
                        let decoder = SCALE.default.decoder(data: data)
                        return try T.init(from: decoder, registry: self.substrate.registry)
                    }.mapError(SubstrateRpcApiError.from)
                }
            cb(result)
        }
    }
    
    public func instantiate(
        request: ContractInstantiateRequest<S.R.TAccountId, S.R.TBalance, S.R.TGas>,
        at hash: S.R.THash?,
        timeout: TimeInterval? = nil,
        cb: @escaping SRpcApiCallback<ContractInstantiateResult<S.R>>
    ) {
        substrate.client.call(
            method: "contracts_instantiate",
            params: RpcCallParams(request, hash),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<ContractInstantiateResult<S.R>>) in
            cb(res.mapError(SubstrateRpcApiError.rpc))
        }
    }
    
    public func instantiate(
        origin: S.R.TAccountId, endowment: S.R.TBalance, gasLimit: S.R.TGas,
        code: Data, data: Data, salt: Data,
        at hash: S.R.THash?,
        timeout: TimeInterval? = nil,
        cb: @escaping SRpcApiCallback<ContractInstantiateResult<S.R>>
    ) {
        let r = ContractInstantiateRequest(
            origin: origin, endowment: endowment, gasLimit: gasLimit,
            code: code, data: data, salt: salt
        )
        self.instantiate(request: r, at: hash, timeout: timeout, cb: cb)
    }
    
    public func rentProjection(address: S.R.TAccountId,
                               at hash: S.R.THash?,
                               timeout: TimeInterval? = nil,
                               cb: @escaping SRpcApiCallback<Optional<S.R.TBlockNumber>>) {
        substrate.client.call(
            method: "contracts_rentProjection",
            params: RpcCallParams(address.bytes, hash),
            timeout: timeout ?? substrate.callTimeout
        ) { (res: RpcClientResult<Optional<Data>>) in
            let result: SRpcApiResult<Optional<S.R.TBlockNumber>> = res
                .mapError(SubstrateRpcApiError.rpc)
                .flatMap {
                    guard let data = $0 else { return .success(nil) }
                    return Result {
                        try S.R.TBlockNumber(jsonData: data)
                    }.mapError(SubstrateRpcApiError.from)
                }
            cb(result)
        }
    }
}

extension SubstrateRpcApiRegistry where S.R: Contracts {
    public var contracts: SubstrateRpcContractsApi<S> { getRpcApi(SubstrateRpcContractsApi<S>.self) }
}
