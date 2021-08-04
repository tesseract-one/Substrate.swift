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
            let result: SRpcApiResult<ContractInstantiateResult<S.R>> = res
                .mapError(SubstrateRpcApiError.rpc)
                .map { res in
                    switch res.result {
                    case .err(_): return res
                    case .ok(let instRes):
                        let fixed = instRes.changedSs58Format(format: self.substrate.properties.ss58Format)
                        return ContractInstantiateResult<S.R>(
                            gasConsumed: res.gasConsumed,
                            gasRequired: res.gasRequired,
                            debugMessage: res.debugMessage,
                            result: .ok(fixed)
                        )
                    }
                }
            cb(result)
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

public typealias ContractCallResult = ContractResult<RpcResult<ContractExecResultValue, DispatchError>>
public typealias ContractInstantiateResult<R: Contracts> = ContractResult<RpcResult<ContractInstResultValue<R.TAccountId, R.TBlockNumber>, DispatchError>>

public struct ContractCallRequest<AccountId: PublicKey, Balance: Encodable, Gas: Encodable>: Encodable {
    public let origin: AccountId
    public let dest: AccountId
    public let value: Balance
    public let gasLimit: Gas
    public let inputData: Data
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(origin.bytes, forKey: .origin)
        try container.encode(dest.bytes, forKey: .dest)
        try container.encode(value, forKey: .value)
        try container.encode(gasLimit, forKey: .gasLimit)
        try container.encode(inputData, forKey: .inputData)
    }
    
    private enum Keys: String, CodingKey {
        case origin
        case dest
        case value
        case gasLimit
        case inputData
    }
}

public struct ContractInstantiateRequest<AccountId: PublicKey, Balance: Encodable, Gas: Encodable>: Encodable {
    public let origin: AccountId
    public let endowment: Balance
    public let gasLimit: Gas
    public let code: Data
    public let data: Data
    public let salt: Data
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encode(origin.bytes, forKey: .origin)
        try container.encode(endowment, forKey: .endowment)
        try container.encode(gasLimit, forKey: .gasLimit)
        try container.encode(code, forKey: .code)
        try container.encode(data, forKey: .data)
        try container.encode(salt, forKey: .salt)
    }
    
    private enum Keys: String, CodingKey {
        case origin
        case endowment
        case code
        case gasLimit
        case salt
        case data
    }
}

public struct ContractResult<T: Decodable>: Decodable {
    public let gasConsumed: UInt64
    public let gasRequired: UInt64
    public let debugMessage: Data
    public let result: T
}

public struct ContractExecResultValue: Decodable {
    public let flags: UInt32
    public let data: Data
}

public struct ContractInstResultValue<AccountId: PublicKey, BN: BlockNumberProtocol>: Decodable {
    public let result: ContractExecResultValue
    public let accountId: AccountId
    public let rentProjection: Optional<RentProjection<BN>>
    
    public init(result: ContractExecResultValue, accountId: AccountId, rentProjection: RentProjection<BN>?) {
        self.result = result
        self.accountId = accountId
        self.rentProjection = rentProjection
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        result = try container.decode(ContractExecResultValue.self, forKey: .result)
        let accData = try container.decode(Data.self, forKey: .accountId)
        accountId = try AccountId(bytes: accData, format: .substrate)
        rentProjection = try container.decode(Optional<RentProjection<BN>>.self, forKey: .rentProjection)
    }
    
    public enum Keys: String, CodingKey {
        case result
        case accountId
        case rentProjection
    }
    
    public func changedSs58Format(format: Ss58AddressFormat) -> Self {
        let newAccount = try! AccountId(bytes: self.accountId.bytes, format: format)
        return Self(result: result, accountId: newAccount, rentProjection: rentProjection)
    }
}

public enum RentProjection<BN: BlockNumberProtocol>: Equatable, Decodable {
    case eviction(at: BN)
    case noEviction
    
    public init(from decoder: Decoder) throws {
        let container1 = try decoder.singleValueContainer()
        if let simple = try? container1.decode(String.self) {
            guard simple == "NoEviction" else {
                throw DecodingError.dataCorruptedError(in: container1, debugDescription: "Unknown case \(simple)")
            }
            self = .noEviction
        } else {
            let container2 = try decoder.container(keyedBy: CodableComplexKey<Self>.self)
            guard let key = container2.allKeys.first else {
                throw DecodingError.dataCorruptedError(in: container1, debugDescription: "Empty case object")
            }
            guard key.stringValue == "EvictionAt" else {
                throw DecodingError.dataCorruptedError(forKey: key, in: container2, debugDescription: "Unknow enum case")
            }
            let data = try container2.decode(Data.self, forKey: key)
            self = try .eviction(at: BN(jsonData: data))
        }
    }
}
