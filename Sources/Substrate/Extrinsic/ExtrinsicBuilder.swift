//
//  ExtrinsicBuilder.swift
//  
//
//  Created by Yehor Popovych on 21.04.2023.
//

import Foundation
import ScaleCodec

public struct ExtrinsicBuilder<S: SomeSubstrate, C: Call, E> {
    public let extrinsic: Extrinsic<C, E>
    public let substrate: S
    
    public init(substrate: S, extinsic: Extrinsic<C, E>) {
        self.substrate = substrate
        self.extrinsic = extinsic
    }
}

extension ExtrinsicBuilder where E == S.RC.TExtrinsicManager.TUnsignedExtra {
    public init(substrate: S, call: C, params: S.RC.TExtrinsicManager.TUnsignedParams) async throws {
        let ext = try await substrate.runtime.extrinsicManager.build(unsigned: call, params: params)
        self.init(substrate: substrate, extinsic: ext)
    }
    
    public func paymentInfo() async throws {
        
    }
    
    public func fetchParameters(
        account: S.RC.TAccountId? = nil, overrides: S.RC.TExtrinsicManager.TSigningParams? = nil
    ) async throws -> S.RC.TExtrinsicManager.TSigningParams {
        var params = try await substrate.runtime.extrinsicManager.build(params: self.extrinsic, overrides: overrides)
        if var nonce = params as? AnyNonceSigningParameter, !nonce.hasNonce {
            guard let account = account else {
                
            }
            let nextIndex = try await substrate.rpc.system.accountNextIndex(id: account)
            nonce.anyNonce = UInt256(nextIndex)
            params = nonce as! S.RC.TExtrinsicManager.TSigningParams
        }
        // TODO: calculate payment info
        return params
    }
    
    public func sign(account: S.RC.TAccountId,
                     overrides: S.RC.TExtrinsicManager.TSigningParams? = nil
    ) async throws -> ExtrinsicBuilder<S, C, S.RC.TExtrinsicManager.TSignedExtra> {
        guard let signer = substrate.signer else {
            
        }
        let params = try await fetchParameters(account: account, overrides: overrides)
        let payload = try await substrate.runtime.extrinsicManager.build(payload: extrinsic, params: params)
        let signature = try await signer.sign(payload: payload, with: account, config: substrate.runtime.config)
        let address = try S.RC.TAddress(accountId: account, runtime: substrate.runtime)
        let signed = try substrate.runtime.extrinsicManager.build(signed: payload,
                                                                  address: address,
                                                                  signature: signature)
        return ExtrinsicBuilder<_, _, _>(substrate: substrate, extinsic: signed)
    }
    
    public func send() async throws {
        
    }
}
