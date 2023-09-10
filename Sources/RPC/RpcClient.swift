//
//  RpcClient.swift
//  
//
//  Created by Yehor Popovych on 08/06/2023.
//

import Foundation
import ScaleCodec
import ContextCodable
import Substrate

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
    public func accountNextIndex(
        id: ST<C>.AccountId, runtime: ExtendedRuntime<C>
    ) async throws -> ST<C>.Index {
        let context = ST<C>.AccountId.EncodingContext(runtime: runtime) {
            try runtime.types.account.get()
        }
        return try await call(method: "system_accountNextIndex",
                              params: [id.any(context: context)])
    }
    
    @inlinable
    public func runtimeVersion(
        at hash: ST<C>.Hash?, metadata: any Metadata,
        config: C, types: DynamicTypes
    ) async throws -> ST<C>.RuntimeVersion {
        return try await call(method: "state_getRuntimeVersion", params: Params(hash), context: metadata)
    }
    
    @inlinable
    public func metadata(at hash: ST<C>.Hash?, config: C) async throws -> Metadata
    {
        do {
            return try await metadataFromRuntimeApi(at: hash, config: config)
        } catch {
            print("Metadata RPC Call fallback: \(error)")
           return try await metadataFromRpc(at: hash, config: config)
        }
    }
    
    @inlinable
    public func systemProperties(
        metadata: any Metadata, config: C, types: DynamicTypes
    ) async throws -> ST<C>.SystemProperties {
        try await call(method: "system_properties", params: Params(), context: metadata)
    }
    
    @inlinable
    public func block(
        hash index: ST<C>.BlockNumber?, metadata: any Metadata,
        config: C, types: DynamicTypes
    ) async throws ->ST<C>.Hash? {
        try await call(method: "chain_getBlockHash", params: Params(index.map(UIntHex.init)),
                       context: { try types.hash.get() })
    }
    
    @inlinable
    public func block(
        at hash: ST<C>.Hash? = nil, runtime: ExtendedRuntime<C>
    ) async throws -> ST<C>.ChainBlock? {
        try await call(method: "chain_getBlock", params: Params(hash),
                       context: (runtime, { try runtime.types.block.get() }))
    }
    
    @inlinable
    public func block(
        header hash: ST<C>.Hash?, runtime: ExtendedRuntime<C>
    ) async throws -> ST<C>.BlockHeader? {
        let context = ST<C>.BlockHeader.DecodingContext(runtime: runtime) {
            try ST<C>.Block.headerType(block: runtime.types.block.get())
        }
        return try await call(method: "chain_getHeader", params: Params(hash),
                              context: context)
    }
    
    public func events(
        at hash: ST<C>.Hash?,
        runtime: ExtendedRuntime<C>
    ) async throws -> ST<C>.BlockEvents? {
        return try await self.storage(value: runtime.eventsStorageKey, at: hash, runtime: runtime)
    }
    
    public func dryRun<CL: Call>(
        extrinsic: ST<C>.SignedExtrinsic<CL>,
        at hash: ST<C>.Hash?,
        runtime: ExtendedRuntime<C>
    ) async throws -> Result<Void, Either<ST<C>.DispatchError, ST<C>.TransactionValidityError>> {
        var encoder = runtime.encoder()
        try runtime.extrinsicManager.encode(signed: extrinsic, in: &encoder, runtime: runtime)
        let dispatchErrorCtx = ST<C>.DispatchError.DecodingContext(runtime: runtime) {
            try runtime.types.dispatchError.get()
        }
        let transactionErrorCtx = ST<C>.TransactionValidityError.DecodingContext(runtime: runtime) {
            try runtime.types.transactionValidityError.get()
        }
        let nothingCtx = RuntimeSwiftCodableContext(runtime: runtime)
        let context = Either<ST<C>.TransactionValidityError, Either<ST<C>.DispatchError, Nothing>>
            .resultContext(
                left: transactionErrorCtx,
                right: Either<ST<C>.DispatchError, Nothing>
                    .resultContext(left: dispatchErrorCtx, right: nothingCtx)
            )
        let result: Either<ST<C>.TransactionValidityError, Either<ST<C>.DispatchError, Nothing>> =
            try await call(method: "system_dryRun",
                           params: Params(encoder.output, hash),
                           context: context)
        return result.result
            .mapError { .right($0) }
            .flatMap { $0.result.map{_ in}.mapError{ .left($0) } }
    }
    
    public func execute<RT: ScaleCodec.Decodable>(call: any StaticCodableRuntimeCall<RT>,
                                                  at hash: ST<C>.Hash?, config: C) async throws -> RT
    {
        var encoder = config.encoder()
        try call.encodeParams(in: &encoder)
        let data: Data = try await self.call(method: "state_call",
                                             params: Params(call.fullName, encoder.output, hash))
        var decoder = config.decoder(data: data)
        return try call.decode(returnFrom: &decoder)
    }
    
    public func execute<RT>(call: any RuntimeCall<RT>,
                            at hash: ST<C>.Hash?,
                            runtime: ExtendedRuntime<C>) async throws -> RT {
        var encoder = runtime.encoder()
        try call.encodeParams(in: &encoder, runtime: runtime)
        let data: Data = try await self.call(method: "state_call",
                                             params: Params(call.fullName, encoder.output, hash))
        var decoder = runtime.decoder(with: data)
        return try call.decode(returnFrom: &decoder, runtime: runtime)
    }
    
    public func submit<CL: Call>(
        extrinsic: ST<C>.SignedExtrinsic<CL>,
        runtime: ExtendedRuntime<C>
    ) async throws -> ST<C>.Hash {
        var encoder = runtime.encoder()
        try runtime.extrinsicManager.encode(signed: extrinsic, in: &encoder, runtime: runtime)
        return try await call(method: "author_submitExtrinsic", params: Params(encoder.output),
                              context: { try runtime.types.hash.get() })
    }
    
    public func storage<V>(value key: any StorageKey<V>,
                           at hash: ST<C>.Hash?,
                           runtime: ExtendedRuntime<C>) async throws -> V?
    {
        let data: Data? = try await call(method: "state_getStorage", params: Params(key.hash, hash))
        return try data.map { data in
            var decoder = runtime.decoder(with: data)
            return try key.decode(valueFrom: &decoder, runtime: runtime)
        }
    }
    
    public func storage(size key: any StorageKey,
                        at hash: ST<C>.Hash?,
                        runtime: ExtendedRuntime<C>) async throws -> UInt64
    {
        let size: HexOrNumber<UInt64>? = try await call(method: "state_getStorageSize",
                                                        params: Params(key.hash, hash))
        return size?.value ?? 0
    }
    
    public func storage<I: StorageKeyIterator>(keys iter: I,
                                               count: Int,
                                               startKey: I.TKey?,
                                               at hash: ST<C>.Hash?,
                                               runtime: ExtendedRuntime<C>) async throws -> [I.TKey] {
        let keys: [Data] = try await call(method: "state_getKeysPaged",
                                          params: Params(iter.hash, count, startKey?.hash, hash))
        return try keys.map { key in
            var decoder = runtime.decoder(with: key)
            return try iter.decode(keyFrom: &decoder, runtime: runtime)
        }
    }
    
    public func storage<K: StorageKey>(
        changes keys: [K], at hash: ST<C>.Hash?, runtime: ExtendedRuntime<C>
    ) async throws -> [(block: ST<C>.Hash, changes: [(key: K, value: K.TValue?)])] {
        let keys = Dictionary(uniqueKeysWithValues: keys.map { ($0.hash, $0) })
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
    
    public func storage(
        anychanges keys: [any StorageKey], at hash: ST<C>.Hash?, runtime: ExtendedRuntime<C>
    ) async throws -> [(block: ST<C>.Hash, changes: [(key: any StorageKey, value: Any?)])] {
        let keys = Dictionary(uniqueKeysWithValues: keys.map { ($0.hash, $0) })
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
    
    public func metadataFromRuntimeApi(at hash: ST<C>.Hash?, config: C) async throws -> Metadata {
        let versions = try await execute(call: config.metadataVersionsCall(),
                                         at: hash, config: config)
        let supported = VersionedNetworkMetadata.supportedVersions.intersection(versions)
        guard let max = supported.max() else {
            throw ScaleCodec.DecodingError.dataCorrupted(
                ScaleCodec.DecodingError.Context(
                    path: [],
                    description: "Unsupported metadata versions \(versions)"))
        }
        let metadata = try await execute(call: config.metadataAtVersionCall(version: max),
                                         at: hash, config: config)
        guard let metadata = metadata else {
            throw ScaleCodec.DecodingError.dataCorrupted(
                ScaleCodec.DecodingError.Context(
                    path: [],
                    description: "Null metadata"))
        }
        return try metadata.metadata(config: config)
    }
    
    public func metadataFromRpc(at hash: ST<C>.Hash?, config: C) async throws -> Metadata {
        let data: Data = try await call(method: "state_getMetadata", params: Params(hash?.raw))
        var decoder = config.decoder(data: data)
        let versioned = try decoder.decode(VersionedNetworkMetadata.self)
        return try versioned.metadata.asMetadata()
    }
    
    private func storage(changes keys: [Data],
                         hash: ST<C>.Hash?,
                         runtime: ExtendedRuntime<C>) async throws -> [ST<C>.StorageChangeSet] {
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
                                   unsubscribe: umethod, context: context)
    }
    
    @inlinable
    public func subscribe<Params: Swift.Encodable, Event: ContextDecodable>(
        method: String, params: Params, unsubscribe umethod: String,
        context: Event.DecodingContext
    ) async throws -> AsyncThrowingStream<Event, Error> {
        try await client.subscribe(method: method, params: params,
                                   unsubscribe: umethod, context: context)
    }
    
    @inlinable
    public func subscribe<Params: ContextEncodable, Event: ContextDecodable>(
        method: String, params: Params, unsubscribe umethod: String,
        encoding econtext: Params.EncodingContext,
        decoding dcontext: Event.DecodingContext
    ) async throws -> AsyncThrowingStream<Event, Error> {
        try await client.subscribe(method: method, params: params,
                                   unsubscribe: umethod, encoding: econtext,
                                   decoding: dcontext)
    }
}

extension RpcClient: SubscribableClient where CL: RpcSubscribableClient {
    public func submitAndWatch<CL: Call>(
        extrinsic: ST<C>.SignedExtrinsic<CL>,
        runtime: ExtendedRuntime<C>
    ) async throws -> AsyncThrowingStream<ST<C>.TransactionStatus, Error> {
        var encoder = runtime.encoder()
        try runtime.extrinsicManager.encode(signed: extrinsic, in: &encoder, runtime: runtime)
        return try await subscribe(method: "author_submitAndWatchExtrinsic",
                                   params: Params(encoder.output),
                                   unsubscribe: "author_unwatchExtrinsic",
                                   context: .init(runtime: runtime))
    }
    
    public func subscribe<K: StorageKey>(
        storage keys: [K],
        runtime: ExtendedRuntime<C>
    ) async throws -> AsyncThrowingStream<(K, K.TValue?), Error> {
        let keys = Dictionary(uniqueKeysWithValues: keys.map { ($0.hash, $0) })
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
        let keys = Dictionary(uniqueKeysWithValues: keys.map { ($0.hash, $0) })
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
    ) async throws -> AsyncThrowingStream<ST<C>.StorageChangeSet, Error> {
        try await subscribe(
           method: "state_subscribeStorage",
           params: keys,
           unsubscribe: "state_unsubscribeStorage",
           context: .init(runtime: runtime)
       )
    }
}
