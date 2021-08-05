//
//  ContractCall.swift
//  
//
//  Created by Yehor Popovych on 05.08.2021.
//

import Foundation

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

public struct ContractExecResultValue: Codable {
    public let flags: UInt32
    public let data: Data
}

public typealias ContractCallResult = ContractResult<RpcResult<ContractExecResultValue, DispatchError>>
