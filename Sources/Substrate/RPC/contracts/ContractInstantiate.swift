//
//  ContractInstantiate.swift
//  
//
//  Created by Yehor Popovych on 05.08.2021.
//

import Foundation

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
        let format = decoder.typeRegistry?.ss58AddressFormat ?? .substrate
        accountId = try AccountId(bytes: accData, format: format)
        rentProjection = try container.decode(Optional<RentProjection<BN>>.self, forKey: .rentProjection)
    }
    
    public enum Keys: String, CodingKey {
        case result
        case accountId
        case rentProjection
    }
}

public typealias ContractInstantiateResult<R: Contracts> = ContractResult<RpcResult<ContractInstResultValue<R.TAccountId, R.TBlockNumber>, DispatchError>>
