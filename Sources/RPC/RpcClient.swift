//
//  RpcClient.swift
//  
//
//  Created by Yehor Popovych on 08/06/2023.
//

import Foundation
import ScaleCodec
import ContextCodable
#if !COCOAPODS
import Substrate
#endif

public struct RpcClient<RC: Config, CL: RpcCallableClient> {
    public let client: CL
    public let rpcMethods: LazyAsyncThrowingProperty<Set<String>>
    
    public init(client: CL) {
        self.client = client
        self.rpcMethods = LazyAsyncThrowingProperty {
            try await Self.rpcMethods(client: client)
        }
    }
    
    private struct RpcMethods: Swift.Codable {
        public let methods: Set<String>
    }
    
    internal static func rpcMethods(client: CL) async throws -> Set<String> {
        let m: RpcMethods = try await client.call(method: "rpc_methods", params: Params())
        return m.methods
    }
}

extension RpcClient: RpcCallableClient {
    @inlinable
    public func call<Params: Swift.Encodable, Res: Swift.Decodable>(
        method: String, params: Params
    ) async throws -> Res {
        try await client.call(method: method, params: params)
    }
    
    @inlinable
    public func call<Params: ContextEncodable, Res: Swift.Decodable>(
        method: String, params: Params, context: Params.EncodingContext
    ) async throws -> Res {
        try await client.call(method: method, params: params, context: context)
    }
    
    @inlinable
    public func call<Params: Swift.Encodable, Res: ContextDecodable>(
        method: String, params: Params, context: Res.DecodingContext
    ) async throws -> Res {
        try await client.call(method: method, params: params, context: context)
    }
    
    @inlinable
    public func call<Params: ContextEncodable, Res: ContextDecodable>(
        method: String, params: Params,
        encoding econtext: Params.EncodingContext,
        decoding dcontext: Res.DecodingContext
    ) async throws -> Res {
        try await client.call(method: method, params: params,
                              encoding: econtext, decoding: dcontext)
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
        let context = RC.TAccountId.EncodingContext(runtime: runtime) {
            try $0.types.account.id
        }
        return try await call(method: "system_accountNextIndex",
                              params: [id.any(context: context)])
    }
    
    @inlinable
    public func runtimeVersion(
        at hash: C.THasher.THash?, metadata: any Metadata, config: C
    ) async throws -> C.TRuntimeVersion {
        return try await call(method: "state_getRuntimeVersion", params: Params(hash), context: metadata)
    }
    
    @inlinable
    public func metadata(at hash: C.THasher.THash?, config: C) async throws -> Metadata {
        do {
            return try await metadataFromRuntimeApi(at: hash, config: config)
        } catch {
            print("Metadata RPC Call fallback: \(error)")
           return try await metadataFromRpc(at: hash, config: config)
        }
    }
    
    @inlinable
    public func systemProperties(metadata: any Metadata, config: C) async throws -> C.TSystemProperties {
        try await call(method: "system_properties", params: Params(), context: metadata)
    }
    
    @inlinable
    public func block(
        hash index: C.TBlock.THeader.TNumber?, metadata: any Metadata, config: C
    ) async throws -> C.TBlock.THeader.THasher.THash? {
        try await call(method: "chain_getBlockHash", params: Params(index.map(UIntHex.init)),
                       context: (metadata, { try config.hashType(metadata: metadata).id }))
    }
    
    @inlinable
    public func block(
        at hash: C.TBlock.THeader.THasher.THash? = nil, runtime: ExtendedRuntime<C>
    ) async throws -> C.TChainBlock? {
        try await call(method: "chain_getBlock", params: Params(hash),
                       context: (runtime, { try $0.types.block.id }))
    }
    
    @inlinable
    public func block(
        header hash: C.TBlock.THeader.THasher.THash?, runtime: ExtendedRuntime<C>
    ) async throws -> C.TBlock.THeader? {
        let context = C.TBlock.THeader.DecodingContext(runtime: runtime) {
            try C.TBlock.headerType(runtime: $0, block: $0.types.block.id)
        }
        return try await call(method: "chain_getHeader", params: Params(hash),
                              context: context)
    }
    
    public func events(
        at hash: C.THasher.THash?,
        runtime: ExtendedRuntime<C>
    ) async throws -> C.TBlockEvents? {
        return try await self.storage(value: runtime.eventsStorageKey, at: hash, runtime: runtime)
    }
    
    public func dryRun<CL: Call>(
        extrinsic: SignedExtrinsic<CL, C.TExtrinsicManager>,
        at hash: C.TBlock.THeader.THasher.THash?,
        runtime: ExtendedRuntime<C>
    ) async throws -> Result<Void, Either<C.TDispatchError, C.TTransactionValidityError>> {
        var encoder = runtime.encoder()
        try runtime.extrinsicManager.encode(signed: extrinsic, in: &encoder)
        let dispatchErrorCtx = C.TDispatchError.DecodingContext(runtime: runtime) {
            try $0.types.dispatchError.id
        }
        let transactionErrorCtx = C.TTransactionValidityError.DecodingContext(runtime: runtime) {
            try $0.types.transactionValidityError.id
        }
        let nothingCtx = RuntimeSwiftCodableContext(runtime: runtime)
        let context = Either<C.TTransactionValidityError, Either<C.TDispatchError, Nothing>>
            .resultContext(
                left: transactionErrorCtx,
                right: Either<C.TDispatchError, Nothing>
                    .resultContext(left: dispatchErrorCtx, right: nothingCtx)
            )
        let result: Either<C.TTransactionValidityError, Either<C.TDispatchError, Nothing>> =
            try await call(method: "system_dryRun",
                           params: Params(encoder.output, hash),
                           context: context)
        return result.result
            .mapError { .right($0) }
            .flatMap { $0.result.map{_ in}.mapError{ .left($0) } }
    }
    
    public func execute<CL: StaticCodableRuntimeCall>(call: CL,
                                                      at hash: C.THasher.THash?,
                                                      config: C) async throws -> CL.TReturn
    {
        var encoder = config.encoder()
        try call.encodeParams(in: &encoder)
        let data: Data = try await self.call(method: "state_call",
                                             params: Params(call.fullName, encoder.output, hash))
        var decoder = config.decoder(data: data)
        return try call.decode(returnFrom: &decoder)
    }
    
    public func execute<CL: RuntimeCall>(call: CL,
                                         at hash: C.THasher.THash?,
                                         runtime: ExtendedRuntime<C>) async throws -> CL.TReturn {
        var encoder = runtime.encoder()
        try call.encodeParams(in: &encoder, runtime: runtime)
        let data: Data = try await self.call(method: "state_call",
                                             params: Params(call.fullName, encoder.output, hash))
        var decoder = runtime.decoder(with: data)
        return try call.decode(returnFrom: &decoder, runtime: runtime)
    }
    
    public func submit<CL: Call>(
        extrinsic: SignedExtrinsic<CL, C.TExtrinsicManager>,
        runtime: ExtendedRuntime<C>
    ) async throws -> C.THasher.THash {
        var encoder = runtime.encoder()
        try runtime.extrinsicManager.encode(signed: extrinsic, in: &encoder)
        return try await call(method: "author_submitExtrinsic", params: Params(encoder.output),
                              context: (runtime.metadata, { try runtime.types.hash.id }))
    }
    
    public func storage<K: StorageKey>(value key: K,
                                       at hash: C.THasher.THash?,
                                       runtime: ExtendedRuntime<C>) async throws -> K.TValue? {
        let data: Data? = try await call(method: "state_getStorage", params: Params(key.hash, hash))
        return try data.map { data in
            var decoder = runtime.decoder(with: data)
            return try key.decode(valueFrom: &decoder, runtime: runtime)
        }
    }
    
    public func storage<I: StorageKeyIterator>(keys iter: I,
                                               count: Int,
                                               startKey: I.TKey?,
                                               at hash: C.THasher.THash?,
                                               runtime: ExtendedRuntime<C>) async throws -> [I.TKey] {
        let keys: [Data] = try await call(method: "state_getKeysPaged",
                                          params: Params(iter.hash, count, startKey?.hash, hash))
        return try keys.map { key in
            var decoder = runtime.decoder(with: key)
            return try iter.decode(keyFrom: &decoder, runtime: runtime)
        }
    }
    
    public func storage<K: StorageKey>(
        changes keys: [K], at hash: C.THasher.THash?, runtime: ExtendedRuntime<C>
    ) async throws -> [(block: C.THasher.THash, changes: [(key: K, value: K.TValue?)])] {
        let keys = Dictionary(uniqueKeysWithValues: try keys.map {try ($0.hash, $0)})
        return try await storage(changes: Array(keys.keys), hash: hash, runtime: runtime).map { chSet in
            let changes = try chSet.changes.map { (khash, val) in
                let key = keys[khash]!
                return try (key, val.map { val in
                    var decoder = runtime.decoder(with: val)
                    return try key.decode(valueFrom: &decoder, runtime: runtime)
                })
            }
            return (block: chSet.block, changes: changes)
        }
    }
    
    public func storage<K: StorageKey>(size key: K,
                                       at hash: C.THasher.THash?,
                                       runtime: ExtendedRuntime<C>) async throws -> UInt64 {
        let size: HexOrNumber<UInt64>? = try await call(method: "state_getStorageSize",
                                                        params: Params(key.hash, hash))
        return size?.value ?? 0
    }
    
    public func storage(
        anychanges keys: [any StorageKey], at hash: C.THasher.THash?, runtime: ExtendedRuntime<C>
    ) async throws -> [(block: C.THasher.THash, changes: [(key: any StorageKey, value: Any?)])] {
        let keys = Dictionary(uniqueKeysWithValues: try keys.map {try ($0.hash, $0)})
        return try await storage(changes: Array(keys.keys), hash: hash, runtime: runtime).map { chSet in
            let changes = try chSet.changes.map { (khash, val) in
                let key = keys[khash]!
                return try (key, val.map { val in
                    var decoder = runtime.decoder(with: val)
                    return try key.decode(valueFrom: &decoder, runtime: runtime)
                })
            }
            return (block: chSet.block, changes: changes)
        }
    }
    
    public func metadataFromRuntimeApi(at hash: C.THasher.THash?, config: C) async throws -> Metadata {
        let versions = try await execute(call: config.metadataVersionsCall(),
                                         at: hash, config: config)
        let supported = VersionedMetadata.supportedVersions.intersection(versions)
        guard let max = supported.max() else {
            throw ScaleCodec.DecodingError.dataCorrupted(
                ScaleCodec.DecodingError.Context(
                    path: [],
                    description: "Unsupported metadata versions \(versions)"))
        }
        let metadata = try await execute(call: config.metadataAtVersionCall(version: max),
                                         at: hash,
                                         config: config)
        guard let metadata = metadata else {
            throw ScaleCodec.DecodingError.dataCorrupted(
                ScaleCodec.DecodingError.Context(
                    path: [],
                    description: "Null metadata"))
        }
        return try metadata.metadata(config: config)
    }
    
    public func metadataFromRpc(at hash: C.THasher.THash?, config: C) async throws -> Metadata {
        let data: Data = try await call(method: "state_getMetadata", params: Params(hash?.raw))
        var decoder = config.decoder(data: data)
        let versioned = try decoder.decode(VersionedMetadata.self)
        return try versioned.metadata.asMetadata()
    }
    
    private func storage(changes keys: [Data],
                         hash: C.THasher.THash?,
                         runtime: ExtendedRuntime<C>) async throws -> [C.TStorageChangeSet] {
        try await call(method: "state_queryStorageAt", params: Params(keys, hash),
                       context: .init(runtime: runtime))
    }
}

extension RpcClient: RpcSubscribableClient where CL: RpcSubscribableClient {
    @inlinable
    public func subscribe<Params: Swift.Encodable, Event: Swift.Decodable>(
        method: String, params: Params, unsubscribe umethod: String
    ) async throws -> AsyncThrowingStream<Event, Error> {
        try await client.subscribe(method: method, params: params, unsubscribe: umethod)
    }
    
    @inlinable
    public func subscribe<Params: ContextEncodable, Event: Swift.Decodable>(
        method: String, params: Params, unsubscribe umethod: String,
        context: Params.EncodingContext
    ) async throws -> AsyncThrowingStream<Event, Error> {
        try await client.subscribe(method: method, params: params,
                                   unsubscribe: method, context: context)
    }
    
    @inlinable
    public func subscribe<Params: Swift.Encodable, Event: ContextDecodable>(
        method: String, params: Params, unsubscribe umethod: String,
        context: Event.DecodingContext
    ) async throws -> AsyncThrowingStream<Event, Error> {
        try await client.subscribe(method: method, params: params,
                                   unsubscribe: method, context: context)
    }
    
    @inlinable
    public func subscribe<Params: ContextEncodable, Event: ContextDecodable>(
        method: String, params: Params, unsubscribe umethod: String,
        encoding econtext: Params.EncodingContext,
        decoding dcontext: Event.DecodingContext
    ) async throws -> AsyncThrowingStream<Event, Error> {
        try await client.subscribe(method: method, params: params,
                                   unsubscribe: method, encoding: econtext,
                                   decoding: dcontext)
    }
}

extension RpcClient: SubscribableClient where CL: RpcSubscribableClient {
    public func submitAndWatch<CL: Call>(
        extrinsic: SignedExtrinsic<CL, C.TExtrinsicManager>,
        runtime: ExtendedRuntime<C>
    ) async throws -> AsyncThrowingStream<C.TTransactionStatus, Error> {
        var encoder = runtime.encoder()
        try runtime.extrinsicManager.encode(signed: extrinsic, in: &encoder)
        return try await subscribe(method: "author_submitAndWatchExtrinsic",
                                   params: Params(encoder.output),
                                   unsubscribe: "author_unwatchExtrinsic",
                                   context: .init(runtime: runtime))
    }
    
    public func subscribe<K: StorageKey>(
        storage keys: [K],
        runtime: ExtendedRuntime<C>
    ) async throws -> AsyncThrowingStream<(K, K.TValue?), Error> {
        let keys = Dictionary(uniqueKeysWithValues: try keys.map {try ($0.hash, $0)})
        return try await subscribe(storage: Array(keys.keys), runtime: runtime).flatMap { changes in
            try changes.changes.map { (khash, val) in
                let key = keys[khash]!
                let value = try val.map { val in
                    var decoder = runtime.decoder(with: val)
                    return try key.decode(valueFrom: &decoder, runtime: runtime)
                }
                return (key, value)
            }.stream
        }.throwingStream
    }
    
    public func subscribe(
        anystorage keys: [any StorageKey],
        runtime: ExtendedRuntime<C>
    ) async throws -> AsyncThrowingStream<(any StorageKey, Any?), Error> {
        let keys = Dictionary(uniqueKeysWithValues: try keys.map {try ($0.hash, $0)})
        return try await subscribe(storage: Array(keys.keys), runtime: runtime).flatMap { changes in
            try changes.changes.map { (khash, val) in
                let key = keys[khash]!
                let value = try val.map { val in
                    var decoder = runtime.decoder(with: val)
                    return try key.decode(valueFrom: &decoder, runtime: runtime)
                }
                return (key, value)
            }.stream
        }.throwingStream
    }
    
    private func subscribe(
        storage keys: [Data],
        runtime: ExtendedRuntime<C>
    ) async throws -> AsyncThrowingStream<C.TStorageChangeSet, Error> {
        try await subscribe(
           method: "state_subscribeStorage",
           params: keys,
           unsubscribe: "state_unsubscribeStorage",
           context: .init(runtime: runtime)
       )
    }
}
