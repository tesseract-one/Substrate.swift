//
//  Client.swift
//  
//
//  Created by Yehor Popovych on 07/06/2023.
//

import Foundation

public protocol Client<C> {
    associatedtype C: Config
    
    var hasDryRun: Bool { get async throws }
    
    // Config based calls (needed for Runtime init)
    func runtimeVersion(at hash: C.TBlock.THeader.THasher.THash?, config: C) async throws -> C.TRuntimeVersion
    func metadata(at hash: C.TBlock.THeader.THasher.THash?, config: C) async throws -> Metadata
    func systemProperties(config: C) async throws -> C.TSystemProperties
    func block(hash index: C.TBlock.THeader.TNumber?, config: C) async throws -> C.TBlock.THeader.THasher.THash?
    
    func block(at hash: C.TBlock.THeader.THasher.THash?,
               runtime: ExtendedRuntime<C>) async throws -> C.TChainBlock?
    func block(header hash: C.TBlock.THeader.THasher.THash?,
               runtime: ExtendedRuntime<C>) async throws -> C.TBlock.THeader?
    
    func accountNextIndex(id: C.TAccountId, runtime: ExtendedRuntime<C>) async throws -> C.TIndex
    func events(
        at hash: C.THasher.THash?,
        runtime: ExtendedRuntime<C>
    ) async throws -> C.TBlockEvents?
    func dryRun<CL: Call>(
        extrinsic: SignedExtrinsic<CL, C.TExtrinsicManager>,
        at hash: C.TBlock.THeader.THasher.THash?,
        runtime: ExtendedRuntime<C>
    ) async throws -> Result<Void, Either<C.TDispatchError, C.TTransactionValidityError>>
    func execute<CL: StaticCodableRuntimeCall>(call: CL,
                                               at hash: C.THasher.THash?,
                                               config: C) async throws -> CL.TReturn
    func execute<CL: RuntimeCall>(call: CL,
                                  at hash: C.THasher.THash?,
                                  runtime: ExtendedRuntime<C>) async throws -> CL.TReturn
    func submit<CL: Call>(
        extrinsic: SignedExtrinsic<CL, C.TExtrinsicManager>,
        runtime: ExtendedRuntime<C>
    ) async throws -> C.THasher.THash
    
    func storage<K: StorageKey>(value key: K,
                                at hash: C.THasher.THash?,
                                runtime: ExtendedRuntime<C>) async throws -> K.TValue?
    
    func storage<I: StorageKeyIterator>(keys iter: I,
                                        count: Int,
                                        startKey: I.TKey?,
                                        at hash: C.THasher.THash?,
                                        runtime: ExtendedRuntime<C>) async throws -> [I.TKey]
    
    func storage<K: StorageKey>(
        changes keys: [K], at hash: C.THasher.THash?, runtime: ExtendedRuntime<C>
    ) async throws -> [(block: C.THasher.THash, changes: [(key: K, value: K.TValue?)])]
    
    func storage<K: StorageKey>(size key: K,
                                at hash: C.THasher.THash?,
                                runtime: ExtendedRuntime<C>) async throws -> UInt64
    
    func storage(
        anychanges keys: [any StorageKey], at hash: C.THasher.THash?, runtime: ExtendedRuntime<C>
    ) async throws -> [(block: C.THasher.THash, changes: [(key: any StorageKey, value: Any?)])]
}

public protocol SubscribableClient<C>: Client {
    func submitAndWatch<CL: Call>(
        extrinsic: SignedExtrinsic<CL, C.TExtrinsicManager>,
        runtime: ExtendedRuntime<C>
    ) async throws -> AsyncThrowingStream<C.TTransactionStatus, Error>
    
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
    func block(hash index: C.TBlock.THeader.TNumber?,
               runtime: ExtendedRuntime<C>) async throws -> C.TBlock.THeader.THasher.THash? {
        try await block(hash: index, config: runtime.config)
    }
}
