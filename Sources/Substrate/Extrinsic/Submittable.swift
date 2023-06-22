//
//  ExtrinsicBuilder.swift
//  
//
//  Created by Yehor Popovych on 21.04.2023.
//

import Foundation
import ScaleCodec

public struct Submittable<S: SomeSubstrate, C: Call, E: ExtrinsicExtra> {
    public let extrinsic: Extrinsic<C, E>
    public let substrate: S
    
    public init(substrate: S, extinsic: Extrinsic<C, E>) {
        self.substrate = substrate
        self.extrinsic = extinsic
    }
}

public enum SubmittableError: Swift.Error {
    case accountAndNonceAreNil
    case signerIsNil
    case dryRunIsNotSupported
    case queryInfoIsNotSupported
    case queryFeeDetailsIsNotSupported
}

extension Submittable where E == S.RC.TExtrinsicManager.TUnsignedExtra {
    public init(substrate: S, call: C, params: S.RC.TExtrinsicManager.TUnsignedParams) async throws {
        let ext = try await substrate.runtime.extrinsicManager.unsigned(call: call, params: params)
        self.init(substrate: substrate, extinsic: ext)
    }
    
    public func dryRun(account: any PublicKey,
                       at block: S.RC.TBlock.THeader.THasher.THash? = nil,
                       overrides: S.RC.TExtrinsicManager.TSigningParams? = nil
    ) async throws -> RpcResult<RpcResult<(), S.RC.TDispatchError>, S.RC.TTransactionValidityError> {
        let signed = try await fakeSign(account: account, overrides: overrides)
        return try await signed.dryRun(at: block)
    }
    
    public func paymentInfo(account: any PublicKey,
                            at block: S.RC.TBlock.THeader.THasher.THash? = nil,
                            overrides: S.RC.TExtrinsicManager.TSigningParams? = nil
    ) async throws -> S.RC.TDispatchInfo {
        let signed = try await fakeSign(account: account, overrides: overrides)
        return try await signed.paymentInfo(at: block)
    }
    
    public func feeDetails(account: any PublicKey,
                           at block: S.RC.TBlock.THeader.THasher.THash? = nil,
                           overrides: S.RC.TExtrinsicManager.TSigningParams? = nil
    ) async throws -> S.RC.TFeeDetails {
        let signed = try await fakeSign(account: account, overrides: overrides)
        return try await signed.feeDetails(at: block)
    }
    
    public func fakeSign(account: any PublicKey,
                         overrides: S.RC.TExtrinsicManager.TSigningParams? = nil
    ) async throws -> Submittable<S, C, S.RC.TExtrinsicManager.TSignedExtra> {
        let params = try await fetchParameters(account: account, overrides: overrides)
        let payload = try await substrate.runtime.extrinsicManager.payload(unsigned: extrinsic, params: params)
        let signature = try S.RC.TSignature(fake: account.algorithm, runtime: substrate.runtime)
        let signed = try substrate.runtime.extrinsicManager.signed(payload: payload,
                                                                   address: account.address(runtime: substrate.runtime),
                                                                   signature: signature)
        return Submittable<_, _, _>(substrate: substrate, extinsic: signed)
    }
    
    public func fetchParameters(
        account: (any PublicKey)? = nil, overrides: S.RC.TExtrinsicManager.TSigningParams? = nil
    ) async throws -> S.RC.TExtrinsicManager.TSigningParams {
        var params = try await substrate.runtime.extrinsicManager.params(unsigned: self.extrinsic,
                                                                         overrides: overrides)
        if var nonce = params as? AnyNonceSigningParameter, !nonce.hasNonce {
            guard let account = account else {
                throw SubmittableError.accountAndNonceAreNil
            }
            let accountId: S.RC.TAccountId = try account.account(runtime: substrate.runtime)
            let nextIndex = try await substrate.client.accountNextIndex(id: accountId,
                                                                        runtime: substrate.runtime)
            try nonce.setNonce(nextIndex)
            params = nonce as! S.RC.TExtrinsicManager.TSigningParams
        }
        if var era = params as? AnyEraSigningParameter {
            if !era.hasEra {
                try era.setEra(S.RC.TExtrinsicEra.immortal)
            }
            if !era.hasBlockHash {
                let eera: S.RC.TExtrinsicEra = try era.getEra()!
                let hash = try await eera.blockHash(substrate: substrate)
                try era.setBlockHash(hash)
            }
            params = era as! S.RC.TExtrinsicManager.TSigningParams
        }
        if var tip = params as? AnyPaymentSigningParameter {
            if !tip.hasTip {
                try tip.setTip(S.RC.TExtrinsicPayment.default)
            }
            params = tip as! S.RC.TExtrinsicManager.TSigningParams
        }
        return params
    }
    
    public func sign(account: any PublicKey,
                     overrides: S.RC.TExtrinsicManager.TSigningParams? = nil
    ) async throws -> Submittable<S, C, S.RC.TExtrinsicManager.TSignedExtra> {
        guard let signer = substrate.signer else {
            throw SubmittableError.signerIsNil
        }
        return try await sign(signer: signer, account: account, overrides: overrides)
    }
    
    public func sign(signer: any Signer,
                     overrides: S.RC.TExtrinsicManager.TSigningParams? = nil
    ) async throws -> Submittable<S, C, S.RC.TExtrinsicManager.TSignedExtra> {
        let account = try await signer.account(type: .account,
                                               algos: S.RC.TSignature.algorithms(runtime: substrate.runtime))
        return try await sign(signer: signer, account: account, overrides: overrides)
    }
    
    public func signAndSend(
        account: any PublicKey,
        overrides: S.RC.TExtrinsicManager.TSigningParams? = nil
    ) async throws -> S.RC.TBlock.THeader.THasher.THash {
        return try await sign(account: account, overrides: overrides).send()
    }
    
    public func signAndSend(
        signer: any Signer,
        overrides: S.RC.TExtrinsicManager.TSigningParams? = nil
    ) async throws -> S.RC.TBlock.THeader.THasher.THash {
        return try await sign(signer: signer, overrides: overrides).send()
    }
    
    private func sign(signer: any Signer,
                      account: any PublicKey,
                      overrides: S.RC.TExtrinsicManager.TSigningParams? = nil
    ) async throws -> Submittable<S, C, S.RC.TExtrinsicManager.TSignedExtra> {
        let params = try await fetchParameters(account: account, overrides: overrides)
        let payload = try await substrate.runtime.extrinsicManager.payload(unsigned: extrinsic, params: params)
        let signature = try await signer.sign(payload: payload, with: account, runtime: substrate.runtime)
        let signed = try substrate.runtime.extrinsicManager.signed(payload: payload,
                                                                   address: account.address(runtime: substrate.runtime),
                                                                   signature: signature)
        return Submittable<_, _, _>(substrate: substrate, extinsic: signed)
    }
}

extension Submittable where E == S.RC.TExtrinsicManager.TUnsignedExtra, S.CL: SubscribableClient {
    public func signSendAndWatch(
        account: any PublicKey,
        overrides: S.RC.TExtrinsicManager.TSigningParams? = nil
    ) async throws -> ExtrinsicProgress<S> {
        return try await sign(account: account, overrides: overrides).sendAndWatch()
    }
    
    public func signSendAndWatch(
        signer: any Signer,
        overrides: S.RC.TExtrinsicManager.TSigningParams? = nil
    ) async throws -> ExtrinsicProgress<S> {
        return try await sign(signer: signer, overrides: overrides).sendAndWatch()
    }
}

extension Submittable where E == S.RC.TExtrinsicManager.TSignedExtra {
    public func dryRun(
        at block: S.RC.TBlock.THeader.THasher.THash? = nil
    ) async throws -> RpcResult<RpcResult<(), S.RC.TDispatchError>, S.RC.TTransactionValidityError> {
        guard try await substrate.client.hasDryRun else {
            throw SubmittableError.dryRunIsNotSupported
        }
        return try await substrate.client.dryRun(extrinsic: extrinsic, at: block,
                                                 runtime: substrate.runtime)
    }
    
    public func paymentInfo(
        at block: S.RC.TBlock.THeader.THasher.THash? = nil
    ) async throws -> S.RC.TDispatchInfo {
        guard substrate.runtime.resolve(runtimeCall: "query_info",
                                        api: "TransactionPaymentApi") != nil else {
            throw SubmittableError.queryInfoIsNotSupported
        }
        let encoder = substrate.runtime.encoder()
        try substrate.runtime.extrinsicManager.encode(signed: extrinsic, in: encoder)
        let call = AnyRuntimeCall<S.RC.TDispatchInfo>(api: "TransactionPaymentApi",
                                                      method: "query_info",
                                                      params: .sequence(
                                                        [.bytes(encoder.output),
                                                         .u256(UInt256(encoder.output.count))]
                                                      ))
        return try await substrate.client.execute(call: call, at: block, runtime: substrate.runtime)
    }
    
    public func feeDetails(
        at block: S.RC.TBlock.THeader.THasher.THash? = nil
    ) async throws -> S.RC.TFeeDetails {
        guard substrate.runtime.resolve(runtimeCall: "query_fee_details",
                                        api: "TransactionPaymentApi") != nil else {
            throw SubmittableError.queryFeeDetailsIsNotSupported
        }
        let encoder = substrate.runtime.encoder()
        try substrate.runtime.extrinsicManager.encode(signed: extrinsic, in: encoder)
        let call = AnyRuntimeCall<S.RC.TFeeDetails>(api: "TransactionPaymentApi",
                                                    method: "query_fee_details",
                                                    params: .sequence(
                                                        [.bytes(encoder.output),
                                                        .u256(UInt256(encoder.output.count))]
                                                    ))
        return try await substrate.client.execute(call: call, at: block, runtime: substrate.runtime)
    }
    
    public func send() async throws -> S.RC.TBlock.THeader.THasher.THash {
        try await substrate.client.submit(extrinsic: extrinsic,
                                          runtime: substrate.runtime)
    }
}

extension Submittable where E == S.RC.TExtrinsicManager.TSignedExtra, S.CL: SubscribableClient {
    public func sendAndWatch() async throws -> ExtrinsicProgress<S> {
        let encoder = substrate.runtime.encoder()
        try substrate.runtime.extrinsicManager.encode(signed: extrinsic, in: encoder)
        let hash = substrate.runtime.typedHasher.hash(data: encoder.output)
        let stream = try await substrate.client.submitAndWatch(extrinsic: extrinsic,
                                                               runtime: substrate.runtime)
        return ExtrinsicProgress(substrate: substrate, hash: hash, stream: stream)
    }
}
