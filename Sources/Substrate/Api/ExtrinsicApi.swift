//
//  RpcApi.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation

public protocol ExtrinsicApi<R> {
    associatedtype R: RootApi
    init(api: R)
}

extension ExtrinsicApi {
    public static var id: ObjectIdentifier { ObjectIdentifier(self) }
}

public class ExtrinsicApiRegistry<R: RootApi>: RootApiAware {
    private let _apis: Synced<[ObjectIdentifier: any ExtrinsicApi]>
    
    public weak var _rootApi: R!
    
    public init(api: R? = nil) {
        self._rootApi = api
        self._apis = Synced(value: [:])
    }
    
    public func _setRootApi(api: R) {
        self._rootApi = api
    }
    
    public func _api<A>() -> A where A: ExtrinsicApi, A.R == R {
        _apis.mutate { apis in
            if let api = apis[A.id] as? A {
                return api
            }
            let api = A(api: _rootApi)
            apis[A.id] = api
            return api
        }
    }
    
    @inlinable
    public func _api<A>(_ t: A.Type) -> A where A: ExtrinsicApi, A.R == R {
        _api()
    }
}

public extension ExtrinsicApiRegistry {
    var signer: any Signer { get throws {
        guard let signer = _rootApi.signer else {
            throw SubmittableError.signerIsNil
        }
        return signer
    }}
    
    func account() async throws -> any PublicKey {
        try await signer.account(
            type: .account,
            algos: _rootApi.runtime.algorithms(signature: ST<R.RC>.Signature.self)
        ).get()
    }
    
    func new<C: Call>(
        call: C,
        params: ST<R.RC>.ExtrinsicUnsignedParams
    ) async throws -> Submittable<R, C, ST<R.RC>.ExtrinsicUnsignedExtra> {
        try await Submittable(api: _rootApi, call: call, params: params)
    }
    
    func submit<C: Call>(
        _ extrinsic: ST<R.RC>.SignedExtrinsic<C>
    ) async throws -> ST<R.RC>.Hash {
        try await _rootApi.client.submit(extrinsic: extrinsic, runtime: _rootApi.runtime)
    }
}

public extension ExtrinsicApiRegistry where ST<R.RC>.ExtrinsicUnsignedParams == Void {
    func new<C: Call>(
        _ call: C
    ) async throws -> Submittable<R, C, ST<R.RC>.ExtrinsicUnsignedExtra> {
        try await Submittable(api: _rootApi, call: call, params: ())
    }
}

public extension ExtrinsicApiRegistry where R.CL: SubscribableClient {
    func submitAndWatch<C: Call>(
        _ extrinsic: ST<R.RC>.SignedExtrinsic<C>
    ) async throws -> AsyncThrowingStream<ST<R.RC>.TransactionStatus, Error> {
        try await _rootApi.client.submitAndWatch(extrinsic: extrinsic, runtime: _rootApi.runtime)
    }
}

public extension ExtrinsicApiRegistry where R.RC: BatchSupportedConfig {
    func batch(
        calls: [any Call], params: ST<R.RC>.ExtrinsicUnsignedParams
    ) async throws -> Submittable<R, ST<R.RC>.BatchCall, ST<R.RC>.ExtrinsicUnsignedExtra> {
        guard _rootApi.runtime.isBatchSupported else {
            throw SubmittableError.batchIsNotSupported
        }
        return try await Submittable(api: _rootApi,
                                     call: R.RC.TBatchCall(calls: calls),
                                     params: params)
    }
    
    @inlinable
    func batch(
        txs: [any CallHolder], params: ST<R.RC>.ExtrinsicUnsignedParams
    ) async throws -> Submittable<R, ST<R.RC>.BatchCall,ST<R.RC>.ExtrinsicUnsignedExtra> {
        try await batch(calls: txs.map{$0.call}, params: params)
    }
    
    func batchAll(
        calls: [any Call], params: ST<R.RC>.ExtrinsicUnsignedParams
    ) async throws -> Submittable<R, ST<R.RC>.BatchAllCall, ST<R.RC>.ExtrinsicUnsignedExtra> {
        guard _rootApi.runtime.isBatchSupported else {
            throw SubmittableError.batchIsNotSupported
        }
        return try await Submittable(api: _rootApi,
                                     call: ST<R.RC>.BatchAllCall(calls: calls),
                                     params: params)
    }
    
    @inlinable
    func batchAll(
        txs: [any CallHolder], params:ST<R.RC>.ExtrinsicUnsignedParams
    ) async throws -> Submittable<R, ST<R.RC>.BatchAllCall, ST<R.RC>.ExtrinsicUnsignedExtra> {
        try await batchAll(calls: txs.map{$0.call}, params: params)
    }
}

public extension ExtrinsicApiRegistry
    where R.RC: BatchSupportedConfig, ST<R.RC>.ExtrinsicUnsignedParams == Void
{
    @inlinable
    func batch(
        _ calls: [any Call]
    ) async throws -> Submittable<R, ST<R.RC>.BatchCall, ST<R.RC>.ExtrinsicUnsignedExtra> {
        try await batch(calls: calls, params: ())
    }
    
    @inlinable
    func batch(
        _ txs: [any CallHolder]
    ) async throws -> Submittable<R, ST<R.RC>.BatchCall, ST<R.RC>.ExtrinsicUnsignedExtra> {
        try await batch(txs: txs, params: ())
    }
    
    @inlinable
    func batchAll(
        _ calls: [any Call]
    ) async throws -> Submittable<R, ST<R.RC>.BatchAllCall, ST<R.RC>.ExtrinsicUnsignedExtra> {
        try await batchAll(calls: calls, params: ())
    }
    
    @inlinable
    func batchAll(
        _ txs: [any CallHolder]
    ) async throws -> Submittable<R, ST<R.RC>.BatchAllCall, ST<R.RC>.ExtrinsicUnsignedExtra> {
        try await batchAll(txs: txs, params: ())
    }
}
