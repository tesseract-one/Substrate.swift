//
//  RpcClient.swift
//  
//
//  Created by Yehor Popovych on 08/06/2023.
//

import Foundation
import ScaleCodec
import JsonRPC

public struct RpcClient<RC: Config, CL: RpcCallableClient & RuntimeHolder> {
    public let client: CL
    public let rpcMethods: LazyAsyncProperty<Set<String>>
    
    public init(client: CL) {
        self.client = client
        self.rpcMethods = LazyAsyncProperty {
            try await Self._rpcMethods(client: client)
        }
    }
    
    private struct RpcMethods: Codable {
        public let methods: Set<String>
    }
    
    private static func _rpcMethods(client: CL) async throws -> Set<String> {
        let m: RpcMethods = try await client.call(method: "rpc_methods", params: Params())
        return m.methods
    }
}

extension RpcClient: RpcCallableClient {
    @inlinable
    public func call<Params: Encodable, Res: Decodable>(
        method: String, params: Params
    ) async throws -> Res {
        try await client.call(method: method, params: params)
    }
}

extension RpcClient: RuntimeHolder {
    @inlinable
    public var runtime: Runtime { client.runtime }
    
    @inlinable
    public func setRuntime(runtime: Runtime) throws {
        try client.setRuntime(runtime: runtime)
    }
}

extension RpcClient: Client {
    public typealias C = RC
    
    @inlinable
    public var hasDryRun: Bool {
        get async throws {
            try await rpcMethods.value.contains("system_dryRun")
        }
    }
    
    @inlinable
    public func accountNextIndex(id: C.TAccountId, runtime: ExtendedRuntime<C>) async throws -> C.TIndex {
        try await call(method: "system_accountNextIndex", params: Params(id))
    }
    
    @inlinable
    public func runtimeVersion(at hash: C.THasher.THash?, config: C) async throws -> C.TRuntimeVersion {
        try await call(method: "state_getRuntimeVersion", params: Params(hash))
    }
    
    @inlinable
    public func metadata(at hash: C.THasher.THash?, config: C) async throws -> Metadata {
        do {
            return try await metadataFromRuntimeApi(at: hash, config: config)
        } catch {
           return try await metadataFromRpc(at: hash, config: config)
        }
    }
    
    @inlinable
    public func systemProperties(config: C) async throws -> C.TSystemProperties {
        try await call(method: "system_properties", params: Params())
    }
    
    @inlinable
    public func block(
        hash index: C.TBlock.THeader.TNumber?, config: C
    ) async throws -> C.TBlock.THeader.THasher.THash? {
        try await call(method: "chain_getBlockHash", params: Params(index.map(UIntHex.init)))
    }
    
    @inlinable
    public func block(
        at hash: C.TBlock.THeader.THasher.THash? = nil, config: C
    ) async throws -> C.TSignedBlock? {
        try await call(method: "chain_getBlock", params: Params(hash))
    }
    
    @inlinable
    public func block(
        header hash: C.TBlock.THeader.THasher.THash?, config: C
    ) async throws -> C.TBlock.THeader? {
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
        runtime: ExtendedRuntime<C>
    ) async throws -> RpcResult<RpcResult<(), C.TDispatchError>, C.TTransactionValidityError> {
        let encoder = runtime.encoder()
        try runtime.extrinsicManager.encode(signed: extrinsic, in: encoder)
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
                                                      at hash: C.THasher.THash?,
                                                      config: C) async throws -> CL.TReturn
    {
        let encoder = config.encoder()
        try call.encodeParams(in: encoder)
        let data: Data = try await self.call(method: "state_call",
                                             params: Params(call.fullName, encoder.output, hash))
        return try call.decode(returnFrom: config.decoder(data: data))
    }
    
    public func execute<CL: RuntimeCall>(call: CL,
                                         at hash: C.THasher.THash?,
                                         runtime: ExtendedRuntime<C>) async throws -> CL.TReturn {
        let encoder = runtime.encoder()
        try call.encodeParams(in: encoder, runtime: runtime)
        let data: Data = try await self.call(method: "state_call",
                                             params: Params(call.fullName, encoder.output, hash))
        return try call.decode(returnFrom: runtime.decoder(with: data),
                               runtime: runtime)
    }
    
    public func submit<CL: Call>(
        extrinsic: SignedExtrinsic<CL, C.TExtrinsicManager>,
        runtime: ExtendedRuntime<C>
    ) async throws -> C.THasher.THash {
        let encoder = runtime.encoder()
        try runtime.extrinsicManager.encode(signed: extrinsic, in: encoder)
        return try await call(method: "author_submitExtrinsic", params: Params(encoder.output))
    }
    
    public func metadataFromRuntimeApi(at hash: C.THasher.THash?, config: C) async throws -> Metadata {
        let versions = try await execute(call: C.TMetadataVersionsRuntimeCall(),
                                         at: hash, config: config)
        let supported = VersionedMetadata.supportedVersions.intersection(versions)
        guard let max = supported.max() else {
            throw SDecodingError.dataCorrupted(
                SDecodingError.Context(
                    path: [],
                    description: "Unsupported metadata versions \(versions)"))
        }
        let metadata = try await execute(call: C.TMetadataAtVersionRuntimeCall(version: max),
                                         at: hash,
                                         config: config)
        guard let metadata = metadata else {
            throw SDecodingError.dataCorrupted(
                SDecodingError.Context(
                    path: [],
                    description: "Null metadata"))
        }
        return metadata.metadata
    }
    
    public func metadataFromRpc(at hash: C.THasher.THash?, config: C) async throws -> Metadata {
        let data: Data = try await call(method: "state_getMetadata", params: Params(hash))
        let versioned = try config.decoder(data: data).decode(VersionedMetadata.self)
        return versioned.metadata
    }
}

extension RpcClient: RpcSubscribableClient where CL: RpcSubscribableClient {
    @inlinable
    public func subscribe<Params: Encodable, Event: Decodable>(
        method: String, params: Params, unsubsribe umethod: String
    ) async throws -> AsyncThrowingStream<Event, Error> {
        try await client.subscribe(method: method, params: params, unsubsribe: umethod)
    }
}

extension RpcClient: SubscribableClient where CL: RpcSubscribableClient {
    public func submitAndWatch<CL: Call>(
        extrinsic: SignedExtrinsic<CL, C.TExtrinsicManager>,
        runtime: ExtendedRuntime<C>
    ) async throws -> AsyncThrowingStream<C.TTransactionStatus, Swift.Error> {
        let encoder = runtime.encoder()
        try runtime.extrinsicManager.encode(signed: extrinsic, in: encoder)
        return try await subscribe(method: "author_submitAndWatchExtrinsic",
                                   params: Params(encoder.output),
                                   unsubsribe: "author_unwatchExtrinsic")
    }
}
