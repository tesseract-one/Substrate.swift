//
//  ExtrinsicBuilder.swift
//  
//
//  Created by Yehor Popovych on 21.04.2023.
//

import Foundation
import ScaleCodec

public struct Submittable<S: SomeSubstrate, C: Call, E> {
    public let extrinsic: Extrinsic<C, E>
    public let substrate: S
    
    public enum Error: Swift.Error {
        case accountAndNonceAreNil
        case signerIsNil
        case dryRunIsNotSupported
        case queryInfoIsNotSupported
        case queryFeeDetailsIsNotSupported
    }
    
    public init(substrate: S, extinsic: Extrinsic<C, E>) {
        self.substrate = substrate
        self.extrinsic = extinsic
    }
}

extension Submittable where E == S.RC.TExtrinsicManager.TUnsignedExtra {
    public init(substrate: S, call: C, params: S.RC.TExtrinsicManager.TUnsignedParams) async throws {
        let ext = try await substrate.runtime.extrinsicManager.unsigned(call: call, params: params)
        self.init(substrate: substrate, extinsic: ext)
    }
    
    public func dryRun(account: any PublicKey,
                       at block: S.RC.TBlock.THeader.THasher.THash? = nil,
                       overrides: S.RC.TExtrinsicManager.TSigningParams? = nil
    ) async throws -> RpcResult<RpcResult<Nil, S.RC.TDispatchError>, S.RC.TTransactionValidityError> {
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
                throw Error.accountAndNonceAreNil
            }
            let accountId: S.RC.TAccountId = try account.account(runtime: substrate.runtime)
            let nextIndex = try await substrate.rpc.system.accountNextIndex(id: accountId)
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
            throw Error.signerIsNil
        }
        let params = try await fetchParameters(account: account, overrides: overrides)
        let payload = try await substrate.runtime.extrinsicManager.payload(unsigned: extrinsic, params: params)
        let signature = try await signer.sign(payload: payload, with: account, runtime: substrate.runtime)
        let signed = try substrate.runtime.extrinsicManager.signed(payload: payload,
                                                                   address: account.address(runtime: substrate.runtime),
                                                                   signature: signature)
        return Submittable<_, _, _>(substrate: substrate, extinsic: signed)
    }
    
    public func signAndSend(
        account: any PublicKey,
        overrides: S.RC.TExtrinsicManager.TSigningParams? = nil
    ) async throws -> S.RC.TBlock.THeader.THasher.THash {
        return try await sign(account: account, overrides: overrides).send()
    }
}

extension Submittable where E == S.RC.TExtrinsicManager.TUnsignedExtra, S.CL: SubscribableRpcClient {
    public func signSendAndWatch(
        account: any PublicKey,
        overrides: S.RC.TExtrinsicManager.TSigningParams? = nil
    ) async throws -> ExtrinsicProgress<S> {
        return try await sign(account: account, overrides: overrides).sendAndWatch()
    }
}

extension Submittable where E == S.RC.TExtrinsicManager.TSignedExtra {
    public func dryRun(
        at block: S.RC.TBlock.THeader.THasher.THash? = nil
    ) async throws -> RpcResult<RpcResult<Nil, S.RC.TDispatchError>, S.RC.TTransactionValidityError> {
        guard try await substrate.rpc.system.hasDryRun() else {
            throw Error.dryRunIsNotSupported
        }
        return try await substrate.rpc.system.dryRun(extrinsic: extrinsic, at: block)
    }
    
    public func paymentInfo(
        at block: S.RC.TBlock.THeader.THasher.THash? = nil
    ) async throws -> S.RC.TDispatchInfo {
        guard substrate.runtime.resolve(runtimeCall: "query_info",
                                        api: "TransactionPaymentApi") != nil else {
            throw Error.queryInfoIsNotSupported
        }
        let encoder = substrate.runtime.encoder()
        try substrate.runtime.extrinsicManager.encode(signed: extrinsic, in: encoder)
        let call = AnyRuntimeCall<S.RC.TDispatchInfo>(api: "TransactionPaymentApi",
                                                      method: "query_info",
                                                      params: .sequence(
                                                        [.bytes(encoder.output),
                                                         .u256(UInt256(encoder.output.count))]
                                                      ))
        return try await substrate.call.execute(call: call, at: block)
    }
    
    public func feeDetails(
        at block: S.RC.TBlock.THeader.THasher.THash? = nil
    ) async throws -> S.RC.TFeeDetails {
        guard substrate.runtime.resolve(runtimeCall: "query_fee_details",
                                        api: "TransactionPaymentApi") != nil else {
            throw Error.queryFeeDetailsIsNotSupported
        }
        let encoder = substrate.runtime.encoder()
        try substrate.runtime.extrinsicManager.encode(signed: extrinsic, in: encoder)
        let call = AnyRuntimeCall<S.RC.TFeeDetails>(api: "TransactionPaymentApi",
                                                    method: "query_fee_details",
                                                    params: .sequence(
                                                        [.bytes(encoder.output),
                                                        .u256(UInt256(encoder.output.count))]
                                                    ))
        return try await substrate.call.execute(call: call, at: block)
    }
    
    public func send() async throws -> S.RC.TBlock.THeader.THasher.THash {
        let encoder = substrate.runtime.encoder()
        try substrate.runtime.extrinsicManager.encode(signed: extrinsic, in: encoder)
        return try await substrate.rpc.author.submit(extrinsic: encoder.output)
    }
}

extension Submittable where E == S.RC.TExtrinsicManager.TSignedExtra, S.CL: SubscribableRpcClient {
    public func sendAndWatch() async throws -> ExtrinsicProgress<S> {
        let encoder = substrate.runtime.encoder()
        try substrate.runtime.extrinsicManager.encode(signed: extrinsic, in: encoder)
        let hash = substrate.runtime.typedHasher.hash(data: encoder.output)
        let stream = try await substrate.rpc.author.submitAndWatch(extrinsic: encoder.output)
        return ExtrinsicProgress(substrate: substrate, hash: hash, stream: stream)
    }
}
