//
//  Client.swift
//  
//
//  Created by Yehor Popovych on 07/06/2023.
//

import Foundation
import ScaleCodec

public protocol Client<C> {
    associatedtype C: Config
    
    var hasDryRun: Bool { get async throws }
    
    func metadata(at hash: ST<C>.Hash?, config: C) async throws -> (any Metadata)
    
    func runtimeVersion(at hash: ST<C>.Hash?, metadata: any Metadata, config: C,
                        types: DynamicTypes) async throws -> ST<C>.RuntimeVersion
    
    func systemProperties(metadata: any Metadata, config: C,
                          types: DynamicTypes) async throws -> ST<C>.SystemProperties
    
    func block(hash index: ST<C>.BlockNumber?, metadata: any Metadata,
               config: C, types: DynamicTypes) async throws -> ST<C>.Hash?
    
    func block(at hash: ST<C>.Hash?,
               runtime: ExtendedRuntime<C>) async throws -> ST<C>.ChainBlock?
    
    func block(header hash: ST<C>.Hash?,
               runtime: ExtendedRuntime<C>) async throws -> ST<C>.BlockHeader?
    
    func accountNextIndex(id: ST<C>.AccountId, runtime: ExtendedRuntime<C>) async throws -> ST<C>.Index
    
    func events(
        at hash: ST<C>.Hash?,
        runtime: ExtendedRuntime<C>
    ) async throws -> ST<C>.BlockEvents?
    
    func dryRun<CL: Call>(
        extrinsic: ST<C>.SignedExtrinsic<CL>,
        at hash: ST<C>.Hash?,
        runtime: ExtendedRuntime<C>
    ) async throws -> Result<Void, Either<ST<C>.DispatchError, ST<C>.TransactionValidityError>>
    
    func execute<RT: ScaleCodec.Decodable>(call: any StaticCodableRuntimeCall<RT>,
                                           at hash: ST<C>.Hash?,
                                           config: C) async throws -> RT
    
    func execute<RT>(call: any RuntimeCall<RT>,
                     at hash: ST<C>.Hash?,
                     runtime: ExtendedRuntime<C>) async throws -> RT
    
    func submit<CL: Call>(
        extrinsic: ST<C>.SignedExtrinsic<CL>,
        runtime: ExtendedRuntime<C>
    ) async throws -> ST<C>.Hash
    
    func storage<V>(value key: any StorageKey<V>,
                    at hash: ST<C>.Hash?,
                    runtime: ExtendedRuntime<C>) async throws -> V?
    
    func storage(size key: any StorageKey,
                 at hash: ST<C>.Hash?,
                 runtime: ExtendedRuntime<C>) async throws -> UInt64
    
    func storage<I: StorageKeyIterator>(keys iter: I,
                                        count: Int,
                                        startKey: I.TKey?,
                                        at hash: ST<C>.Hash?,
                                        runtime: ExtendedRuntime<C>) async throws -> [I.TKey]
    
    func storage<K: StorageKey>(
        changes keys: [K], at hash: ST<C>.Hash?, runtime: ExtendedRuntime<C>
    ) async throws -> [(block: ST<C>.Hash, changes: [(key: K, value: K.TValue?)])]
    
    func storage(
        anychanges keys: [any StorageKey], at hash: ST<C>.Hash?, runtime: ExtendedRuntime<C>
    ) async throws -> [(block: ST<C>.Hash, changes: [(key: any StorageKey, value: Any?)])]
}

public protocol SubscribableClient<C>: Client {
    func submitAndWatch<CL: Call>(
        extrinsic: ST<C>.SignedExtrinsic<CL>,
        runtime: ExtendedRuntime<C>
    ) async throws -> AsyncThrowingStream<ST<C>.TransactionStatus, Error>
    
    func subscribe<K: StorageKey>(
        storage keys: [K],
        runtime: ExtendedRuntime<C>
    ) async throws -> AsyncThrowingStream<(K, K.TValue?), Error>
    
    func subscribe(
        anystorage keys: [any StorageKey],
        runtime: ExtendedRuntime<C>
    ) async throws -> AsyncThrowingStream<(any StorageKey, Any?), Error>
}

public extension Client {
    @inlinable
    func block(hash index: ST<C>.BlockNumber?,
               runtime: ExtendedRuntime<C>) async throws -> ST<C>.Hash? {
        try await block(hash: index, metadata: runtime.metadata,
                        config: runtime.config, types: runtime.types)
    }
}
