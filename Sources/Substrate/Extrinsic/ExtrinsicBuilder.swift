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
    
    public enum Error: Swift.Error {
        case accountAndNonceAreNil
        case signerIsNil
    }
    
    public init(substrate: S, extinsic: Extrinsic<C, E>) {
        self.substrate = substrate
        self.extrinsic = extinsic
    }
}

extension ExtrinsicBuilder where E == S.RC.TExtrinsicManager.TUnsignedExtra {
    public init(substrate: S, call: C, params: S.RC.TExtrinsicManager.TUnsignedParams) async throws {
        let ext = try await substrate.runtime.extrinsicManager.unsigned(call: call, params: params)
        self.init(substrate: substrate, extinsic: ext)
    }
    
    public func paymentInfo() async throws {
        
    }
    
    public func fakeSign(account: PublicKey,
                         overrides: S.RC.TExtrinsicManager.TSigningParams? = nil
    ) async throws -> ExtrinsicBuilder<S, C, S.RC.TExtrinsicManager.TSignedExtra> {
        let params = try await fetchParameters(account: account, overrides: overrides)
        let payload = try await substrate.runtime.extrinsicManager.payload(unsigned: extrinsic, params: params)
        let signature = try S.RC.TSignature(fake: account.type, runtime: substrate.runtime)
        let signed = try substrate.runtime.extrinsicManager.signed(payload: payload,
                                                                   address: account.address(runtime: substrate.runtime),
                                                                   signature: signature)
        return ExtrinsicBuilder<_, _, _>(substrate: substrate, extinsic: signed)
    }
    
    public func fetchParameters(
        account: PublicKey? = nil, overrides: S.RC.TExtrinsicManager.TSigningParams? = nil
    ) async throws -> S.RC.TExtrinsicManager.TSigningParams {
        var params = try await substrate.runtime.extrinsicManager.params(unsigned: self.extrinsic, overrides: overrides)
        if var nonce = params as? AnyNonceSigningParameter, !nonce.hasNonce {
            guard let account = account else {
                throw Error.accountAndNonceAreNil
            }
            let accountId: S.RC.TAccountId = try account.account(runtime: substrate.runtime)
            let nextIndex = try await substrate.rpc.system.accountNextIndex(id: accountId)
            nonce.anyNonce = UInt256(nextIndex)
            params = nonce as! S.RC.TExtrinsicManager.TSigningParams
        }
        // TODO: calculate payment info
        return params
    }
    
    public func sign(account: PublicKey,
                     overrides: S.RC.TExtrinsicManager.TSigningParams? = nil
    ) async throws -> ExtrinsicBuilder<S, C, S.RC.TExtrinsicManager.TSignedExtra> {
        guard let signer = substrate.signer else {
            throw Error.signerIsNil
        }
        let params = try await fetchParameters(account: account, overrides: overrides)
        let payload = try await substrate.runtime.extrinsicManager.payload(unsigned: extrinsic, params: params)
        let signature = try await signer.sign(payload: payload, with: account, config: substrate.runtime.config)
        let signed = try substrate.runtime.extrinsicManager.signed(payload: payload,
                                                                   address: account.address(runtime: substrate.runtime),
                                                                   signature: signature)
        return ExtrinsicBuilder<_, _, _>(substrate: substrate, extinsic: signed)
    }
    
    public func send() async throws {
        
    }
}
