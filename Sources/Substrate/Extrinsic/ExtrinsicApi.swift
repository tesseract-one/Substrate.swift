//
//  RpcApi.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import ScaleCodec
import JsonRPC
import Serializable
#if !COCOAPODS
import JsonRPCSerializable
#endif

public protocol ExtrinsicApi<S> {
    associatedtype S: SomeSubstrate
    var substrate: S! { get }
    init(substrate: S)
    static var id: String { get }
}

extension ExtrinsicApi {
    public static var id: String { String(describing: self) }
}

public class ExtrinsicApiRegistry<S: SomeSubstrate> {
    private let _apis: Synced<[String: any ExtrinsicApi]>
    
    public weak var substrate: S!
    
    public init(substrate: S? = nil) {
        self.substrate = substrate
        self._apis = Synced(value: [:])
    }
    
    public func setSubstrate(substrate: S) {
        self.substrate = substrate
    }
    
    public func getApi<A>(_ t: A.Type) -> A where A: ExtrinsicApi, A.S == S {
        _apis.sync { apis in
            if let api = apis[A.id] as? A {
                return api
            }
            let api = A(substrate: substrate)
            apis[A.id] = api
            return api
        }
    }
}

public extension ExtrinsicApiRegistry {
    var signer: any Signer { get throws {
        guard let signer = substrate.signer else {
            throw SubmittableError.signerIsNil
        }
        return signer
    }}
    
    func account() async throws -> any PublicKey {
        try await signer.account(type: .account,
                                 algos: S.RC.TSignature.algorithms(runtime: substrate.runtime))
    }
    
    func new<C: Call>(
        call: C,
        params: S.RC.TExtrinsicManager.TUnsignedParams
    ) async throws -> Submittable<S, C, S.RC.TExtrinsicManager.TUnsignedExtra> {
        try await Submittable(substrate: substrate, call: call, params: params)
    }
    
    func submit<C: Call>(
        _ extrinsic: SignedExtrinsic<C, S.RC.TExtrinsicManager>
    ) async throws -> S.RC.THasher.THash {
        try await substrate.client.submit(extrinsic: extrinsic, runtime: substrate.runtime)
    }
}

public extension ExtrinsicApiRegistry where S.RC.TExtrinsicManager.TUnsignedParams == Void {
    func new<C: Call>(
        _ call: C
    ) async throws -> Submittable<S, C, S.RC.TExtrinsicManager.TUnsignedExtra> {
        try await Submittable(substrate: substrate, call: call, params: ())
    }
}

public extension ExtrinsicApiRegistry where S.CL: SubscribableClient {
    func submitAndWatch<C: Call>(
        _ extrinsic: SignedExtrinsic<C, S.RC.TExtrinsicManager>
    ) async throws -> AsyncThrowingStream<S.RC.TTransactionStatus, Error> {
        try await substrate.client.submitAndWatch(extrinsic: extrinsic, runtime: substrate.runtime)
    }
}

public extension ExtrinsicApiRegistry where S.RC: BatchSupportedConfig {
    func batch(
        calls: [Call], params: S.RC.TExtrinsicManager.TUnsignedParams
    ) async throws -> Submittable<S, S.RC.TBatchCall, S.RC.TExtrinsicManager.TUnsignedExtra> {
        guard substrate.runtime.isBatchSupported else {
            throw SubmittableError.batchIsNotSupported
        }
        return try await Submittable(substrate: substrate,
                                     call: S.RC.TBatchCall(calls: calls),
                                     params: params)
    }
    
    func batchAll(
        calls: [Call], params: S.RC.TExtrinsicManager.TUnsignedParams
    ) async throws -> Submittable<S, S.RC.TBatchAllCall, S.RC.TExtrinsicManager.TUnsignedExtra> {
        guard substrate.runtime.isBatchSupported else {
            throw SubmittableError.batchIsNotSupported
        }
        return try await Submittable(substrate: substrate,
                                     call: S.RC.TBatchAllCall(calls: calls),
                                     params: params)
    }
}

public extension ExtrinsicApiRegistry
    where S.RC: BatchSupportedConfig, S.RC.TExtrinsicManager.TUnsignedParams == Void
{
    @inlinable
    func batch(
        _ calls: [Call]
    ) async throws -> Submittable<S, S.RC.TBatchCall, S.RC.TExtrinsicManager.TUnsignedExtra> {
        try await batch(calls: calls, params: ())
    }
    
    @inlinable
    func batchAll(
        _ calls: [Call]
    ) async throws -> Submittable<S, S.RC.TBatchAllCall, S.RC.TExtrinsicManager.TUnsignedExtra> {
        try await batchAll(calls: calls, params: ())
    }
}
