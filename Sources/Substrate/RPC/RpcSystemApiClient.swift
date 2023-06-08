//
//  RpcSystemApiClient.swift
//  
//
//  Created by Yehor Popovych on 08/06/2023.
//

import Foundation
import ScaleCodec
import JsonRPC


public class RpcSystemApiClient<RC: RuntimeConfig, CL: CallableClient & RuntimeHolder> {
    public let client: CL
    public private(set) var rpcMethods: LazyAsyncProperty<Set<String>>!
    
    public init(client: CL) {
        self.client = client
        self.rpcMethods = LazyAsyncProperty { [unowned self] in
            try await self._rpcMethods()
        }
    }
    
    private struct RpcMethods: Codable {
        public let methods: Set<String>
    }
    
    private func _rpcMethods() async throws -> Set<String> {
        let m: RpcMethods = try await call(method: "rpc_methods", params: Params())
        return m.methods
    }
}

extension RpcSystemApiClient: CallableClient {
    @inlinable
    public func call<Params: Encodable, Res: Decodable>(
        method: String, params: Params
    ) async throws -> Res {
        try await client.call(method: method, params: params)
    }
}

extension RpcSystemApiClient: RuntimeHolder {
    @inlinable
    public var runtime: Runtime { client.runtime }
    
    @inlinable
    public func setRuntime(runtime: Runtime) throws {
        try client.setRuntime(runtime: runtime)
    }
}

extension RpcSystemApiClient: SystemApiClient {
    public typealias C = RC
    
    @inlinable
    public var hasDryRun: Bool {
        get async throws {
            try await rpcMethods.value.contains("system_dryRun")
        }
    }
    
    @inlinable
    public func accountNextIndex(id: C.TAccountId) async throws -> C.TIndex {
        try await call(method: "system_accountNextIndex", params: Params(id))
    }
    
    @inlinable
    public func runtimeVersion(at hash: C.THasher.THash?) async throws -> C.TRuntimeVersion {
        try await call(method: "state_getRuntimeVersion", params: Params(hash))
    }
    
    @inlinable
    public func metadata(at hash: C.THasher.THash?) async throws -> Metadata {
        do {
            return try await metadataFromRuntimeApi(at: hash)
        } catch {
           return try await metadataFromRpc(at: hash)
        }
    }
    
    @inlinable
    public func systemProperties() async throws -> C.TSystemProperties {
        try await call(method: "system_properties", params: Params())
    }
    
    @inlinable
    public func block(hash index: C.TBlock.THeader.TNumber?) async throws -> C.TBlock.THeader.THasher.THash? {
        try await call(method: "chain_getBlockHash", params: Params(index.map(UIntHex.init)))
    }
    
    @inlinable
    public func block(at hash: C.TBlock.THeader.THasher.THash? = nil) async throws -> C.TSignedBlock? {
        try await call(method: "chain_getBlock", params: Params(hash))
    }
    
    @inlinable
    public func block(header hash: C.TBlock.THeader.THasher.THash?) async throws -> C.TBlock.THeader? {
        try await call(method: "chain_getHeader", params: Params(hash))
    }
    
    public func events(
        at hash: C.THasher.THash?,
        runtime: ExtendedRuntime<C>
    ) async throws -> C.TBlockEvents? {
        let keyHash = try runtime.eventsStorageKey.hash(runtime: runtime)
        let data: Data? = try await call(method: "state_getStorage", params: Params(keyHash, hash))
        guard let data = data, data.count > 0 else {
            return nil
        }
        return try runtime.eventsStorageKey.decode(valueFrom: runtime.decoder(with: data), runtime: runtime)
    }
    
    public func dryRun<CL: Call>(
        extrinsic: SignedExtrinsic<CL, C.TExtrinsicManager>,
        at hash: C.TBlock.THeader.THasher.THash?,
        manager: C.TExtrinsicManager
    ) async throws -> RpcResult<RpcResult<(), C.TDispatchError>, C.TTransactionValidityError> {
        let encoder = runtime.encoder()
        try manager.encode(signed: extrinsic, in: encoder)
        let result: RpcResult<RpcResult<Nil, C.TDispatchError>, C.TTransactionValidityError> =
            try await call(method: "system_dryRun", params: Params(encoder.output, hash))
        if let value = result.value {
            if value.isOk {
                return .ok(.ok(()))
            } else {
                return .ok(.err(value.error!))
            }
        }
        return .err(result.error!)
    }
    
    public func execute<CL: StaticCodableRuntimeCall>(call: CL,
                                               at hash: C.THasher.THash?) async throws -> CL.TReturn
    {
        let encoder = SCALE.default.encoder()
        try call.encodeParams(in: encoder)
        let data: Data = try await self.call(method: "state_call",
                                             params: Params(call.fullName, encoder.output, hash))
        return try call.decode(returnFrom: SCALE.default.decoder(data: data))
    }
    
    public func execute<CL: RuntimeCall>(call: CL,
                                         at hash: C.THasher.THash?) async throws -> CL.TReturn {
        let encoder = runtime.encoder()
        try call.encodeParams(in: encoder, runtime: runtime)
        let data: Data = try await self.call(method: "state_call",
                                             params: Params(call.fullName, encoder.output, hash))
        return try call.decode(returnFrom: runtime.decoder(with: data),
                               runtime: runtime)
    }
    
    public func submit<CL: Call>(
        extrinsic: SignedExtrinsic<CL, C.TExtrinsicManager>,
        manager: C.TExtrinsicManager
    ) async throws -> C.THasher.THash {
        let encoder = runtime.encoder()
        try manager.encode(signed: extrinsic, in: encoder)
        return try await call(method: "author_submitExtrinsic", params: Params(encoder.output))
    }
    
    public func metadataFromRuntimeApi(at hash: C.THasher.THash?) async throws -> Metadata {
        let versions = try await execute(call: MetadataRuntimeApi.MetadataVersions(), at: hash)
        let supported = VersionedMetadata.supportedVersions.intersection(versions)
        guard let max = supported.max() else {
            throw SDecodingError.dataCorrupted(
                SDecodingError.Context(
                    path: [],
                    description: "Unsupported metadata versions \(versions)"))
        }
        let data = try await execute(call: MetadataRuntimeApi.MetadataAtVersion(version: max),
                                     at: hash)
        guard let data = data else {
            throw SDecodingError.dataCorrupted(
                SDecodingError.Context(
                    path: [],
                    description: "Null metadata"))
        }
        return try VersionedMetadata(from: SCALE.default.decoder(data: data)).metadata
    }
    
    public func metadataFromRpc(at hash: C.THasher.THash?) async throws -> Metadata {
        let data: Data = try await call(method: "state_getMetadata", params: Params(hash))
        let versioned = try SCALE.default.decode(VersionedMetadata.self, from: data)
        return versioned.metadata
    }
}

extension RpcSystemApiClient: SubscribableClient where CL: SubscribableClient {
    @inlinable
    public func subscribe<Params: Encodable, Event: Decodable>(
        method: String, params: Params, unsubsribe umethod: String
    ) async throws -> AsyncThrowingStream<Event, Error> {
        try await client.subscribe(method: method, params: params, unsubsribe: umethod)
    }
}

extension RpcSystemApiClient: SubscribableSystemApiClient where CL: SubscribableClient {
    public func submitAndWatch<CL: Call>(
        extrinsic: SignedExtrinsic<CL, C.TExtrinsicManager>,
        manager: C.TExtrinsicManager
    ) async throws -> AsyncThrowingStream<C.TTransactionStatus, Swift.Error> {
        let encoder = runtime.encoder()
        try manager.encode(signed: extrinsic, in: encoder)
        return try await subscribe(method: "author_submitAndWatchExtrinsic",
                                   params: Params(encoder.output),
                                   unsubsribe: "author_unwatchExtrinsic")
    }
}
