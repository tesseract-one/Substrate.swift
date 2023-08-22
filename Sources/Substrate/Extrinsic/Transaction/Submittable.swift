//
//  ExtrinsicBuilder.swift
//  
//
//  Created by Yehor Popovych on 21.04.2023.
//

import Foundation
import ScaleCodec

public struct Submittable<R: RootApi, C: Call, E: ExtrinsicExtra>: CallHolder {
    public typealias TCall = C
    
    public typealias THash = R.RC.THasher.THash
    public typealias TUnsignedParams = R.RC.TExtrinsicManager.TUnsignedParams
    public typealias TSigningParams = R.RC.TExtrinsicManager.TSigningParams
    public typealias TUnsignedExtra = R.RC.TExtrinsicManager.TUnsignedExtra
    public typealias TSignedExtra = R.RC.TExtrinsicManager.TSignedExtra
    
    public let extrinsic: Extrinsic<C, E>
    public let api: R
    @inlinable public var call: C { extrinsic.call }
    
    public init(api: R, extinsic: Extrinsic<C, E>) {
        self.api = api
        self.extrinsic = extinsic
    }
}

public enum SubmittableError: Swift.Error {
    case accountAndNonceAreNil
    case signerIsNil
    case dryRunIsNotSupported
    case queryInfoIsNotSupported
    case queryFeeDetailsIsNotSupported
    case batchIsNotSupported
}

extension Submittable where E == TUnsignedExtra {
    public init(api: R, call: C, params: TUnsignedParams) async throws {
        let ext = try await api.runtime.extrinsicManager.unsigned(call: call, params: params, for: api)
        self.init(api: api, extinsic: ext)
    }
    
    public func dryRun(account: any PublicKey,
                       at block: THash? = nil,
                       overrides: TSigningParams.TPartial? = nil
    ) async throws -> Result<Void, Either<R.RC.TDispatchError, R.RC.TTransactionValidityError>> {
        let signed = try await fakeSign(account: account, overrides: overrides)
        return try await signed.dryRun(at: block)
    }
    
    public func paymentInfo(account: any PublicKey,
                            at block: THash? = nil,
                            overrides: TSigningParams.TPartial? = nil
    ) async throws -> R.RC.TDispatchInfo {
        let signed = try await fakeSign(account: account, overrides: overrides)
        return try await signed.paymentInfo(at: block)
    }
    
    public func feeDetails(account: any PublicKey,
                           at block: THash? = nil,
                           overrides: TSigningParams.TPartial? = nil
    ) async throws -> R.RC.TFeeDetails {
        let signed = try await fakeSign(account: account, overrides: overrides)
        return try await signed.feeDetails(at: block)
    }
    
    public func fakeSign(account: any PublicKey,
                         overrides: TSigningParams.TPartial? = nil
    ) async throws -> Submittable<R, C, TSignedExtra> {
        let params = try await fetchParameters(account: account, partial: overrides ?? .default)
        let payload = try await api.runtime.extrinsicManager.payload(unsigned: extrinsic, params: params, for: api)
        let signature = try api.runtime.create(fakeSignature: R.RC.TSignature.self,
                                               algorithm: account.algorithm)
        let signed = try api.runtime.extrinsicManager.signed(payload: payload,
                                                             address: account.address(in: api),
                                                             signature: signature,
                                                             runtime: api.runtime)
        return Submittable<_, _, _>(api: api, extinsic: signed)
    }
    
    public func fetchParameters(
        account: (any PublicKey)? = nil, partial: TSigningParams.TPartial
    ) async throws -> TSigningParams {
        var partial = partial
        if let account = account, var param = partial as? AnyAccountPartialSigningParameter {
            let accountId: R.RC.TAccountId = try account.account(runtime: api.runtime)
            try param.setAccount(accountId)
            partial = param as! TSigningParams.TPartial
        }
        return try await api.runtime.extrinsicManager.params(unsigned: self.extrinsic,
                                                             partial: partial, for: api)
    }
    
    public func sign(account: any PublicKey,
                     overrides: TSigningParams.TPartial? = nil
    ) async throws -> Submittable<R, C, TSignedExtra> {
        guard let signer = api.signer else {
            throw SubmittableError.signerIsNil
        }
        return try await sign(signer: signer, account: account, overrides: overrides)
    }
    
    public func sign(signer: any Signer,
                     overrides: TSigningParams.TPartial? = nil
    ) async throws -> Submittable<R, C, TSignedExtra> {
        let account = try await signer.account(
            type: .account,
            algos: api.runtime.algorithms(signature: R.RC.TSignature.self)
        ).get()
        return try await sign(signer: signer, account: account, overrides: overrides)
    }
    
    public func signAndSend(
        account: any PublicKey,
        overrides: TSigningParams.TPartial? = nil
    ) async throws -> THash {
        return try await sign(account: account, overrides: overrides).send()
    }
    
    public func signAndSend(
        signer: any Signer,
        overrides: TSigningParams.TPartial? = nil
    ) async throws -> THash {
        return try await sign(signer: signer, overrides: overrides).send()
    }
    
    private func sign(signer: any Signer,
                      account: any PublicKey,
                      overrides: TSigningParams.TPartial? = nil
    ) async throws -> Submittable<R, C, TSignedExtra> {
        let params = try await fetchParameters(account: account, partial: overrides ?? .default)
        let payload = try await api.runtime.extrinsicManager.payload(unsigned: extrinsic,
                                                                     params: params, for: api)
        let signature = try await signer.sign(payload: payload,
                                              with: account,
                                              runtime: api.runtime).get()
        let signed = try api.runtime.extrinsicManager.signed(payload: payload,
                                                             address: account.address(in: api),
                                                             signature: signature,
                                                             runtime: api.runtime)
        return Submittable<_, _, _>(api: api, extinsic: signed)
    }
    
    public func serialize() throws -> Data {
        var encoder = api.runtime.encoder()
        try api.runtime.extrinsicManager.encode(unsigned: extrinsic, in: &encoder,
                                                runtime: api.runtime)
        return encoder.output
    }
}

extension Submittable where E == TUnsignedExtra, R.CL: SubscribableClient {
    public func signSendAndWatch(
        account: any PublicKey,
        overrides: TSigningParams.TPartial? = nil
    ) async throws -> ExtrinsicProgress<R> {
        return try await sign(account: account, overrides: overrides).sendAndWatch()
    }
    
    public func signSendAndWatch(
        signer: any Signer,
        overrides: TSigningParams.TPartial? = nil
    ) async throws -> ExtrinsicProgress<R> {
        return try await sign(signer: signer, overrides: overrides).sendAndWatch()
    }
}

extension Submittable where E == TSignedExtra {
    public func dryRun(
        at block: THash? = nil
    ) async throws -> Result<Void, Either<R.RC.TDispatchError, R.RC.TTransactionValidityError>> {
        guard try await api.client.hasDryRun else {
            throw SubmittableError.dryRunIsNotSupported
        }
        return try await api.client.dryRun(extrinsic: extrinsic, at: block,
                                           runtime: api.runtime)
    }
    
    public func paymentInfo(
        at block: THash? = nil
    ) async throws -> R.RC.TDispatchInfo {
        let call = try api.runtime.queryInfoCall(extrinsic: extrinsic)
        guard api.call.has(call: call) else {
            throw SubmittableError.queryInfoIsNotSupported
        }
        return try await api.client.execute(call: call, at: block, runtime: api.runtime)
    }
    
    public func feeDetails(
        at block: THash? = nil
    ) async throws -> R.RC.TFeeDetails {
        let call = try api.runtime.queryFeeDetailsCall(extrinsic: extrinsic)
        guard api.call.has(call: call) else {
            throw SubmittableError.queryFeeDetailsIsNotSupported
        }
        return try await api.client.execute(call: call, at: block, runtime: api.runtime)
    }
    
    public func send() async throws -> THash {
        try await api.client.submit(extrinsic: extrinsic,
                                    runtime: api.runtime)
    }
    
    public func serialize() throws -> Data {
        var encoder = api.runtime.encoder()
        try api.runtime.extrinsicManager.encode(signed: extrinsic, in: &encoder,
                                                runtime: api.runtime)
        return encoder.output
    }
}

extension Submittable where E == R.RC.TExtrinsicManager.TSignedExtra, R.CL: SubscribableClient {
    public func sendAndWatch() async throws -> ExtrinsicProgress<R> {
        var encoder = api.runtime.encoder()
        try api.runtime.extrinsicManager.encode(signed: extrinsic, in: &encoder,
                                                runtime: api.runtime)
        let hash = try api.runtime.hash(data: encoder.output)
        let stream = try await api.client.submitAndWatch(extrinsic: extrinsic,
                                                         runtime: api.runtime)
        return ExtrinsicProgress(api: api, hash: hash, stream: stream)
    }
}
