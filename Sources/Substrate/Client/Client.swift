//
//  Client.swift
//  
//
//  Created by Yehor Popovych on 07/06/2023.
//

import Foundation

public protocol Client<C>: RuntimeHolder {
    associatedtype C: Config
    
    var hasDryRun: Bool { get async throws }
    
    func runtimeVersion(at hash: C.TBlock.THeader.THasher.THash?, config: C) async throws -> C.TRuntimeVersion
    func metadata(at hash: C.TBlock.THeader.THasher.THash?, config: C) async throws -> Metadata
    func systemProperties(config: C) async throws -> C.TSystemProperties
    func block(hash index: C.TBlock.THeader.TNumber?, config: C) async throws -> C.TBlock.THeader.THasher.THash?
    func block(at hash: C.TBlock.THeader.THasher.THash?, config: C) async throws -> C.TSignedBlock?
    func block(header hash: C.TBlock.THeader.THasher.THash?, config: C) async throws -> C.TBlock.THeader?
    
    func accountNextIndex(id: C.TAccountId, runtime: ExtendedRuntime<C>) async throws -> C.TIndex
    func events(
        at hash: C.THasher.THash?,
        runtime: ExtendedRuntime<C>
    ) async throws -> C.TBlockEvents?
    func dryRun<CL: Call>(
        extrinsic: SignedExtrinsic<CL, C.TExtrinsicManager>,
        at hash: C.TBlock.THeader.THasher.THash?,
        runtime: ExtendedRuntime<C>
    ) async throws -> RpcResult<RpcResult<(), C.TDispatchError>, C.TTransactionValidityError>
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
}

public protocol SubscribableClient<C>: Client {
    func submitAndWatch<CL: Call>(
        extrinsic: SignedExtrinsic<CL, C.TExtrinsicManager>,
        runtime: ExtendedRuntime<C>
    ) async throws -> AsyncThrowingStream<C.TTransactionStatus, Error>
}

public extension Client {
    @inlinable
    func block(hash index: C.TBlock.THeader.TNumber?,
               runtime: ExtendedRuntime<C>) async throws -> C.TBlock.THeader.THasher.THash? {
        try await block(hash: index, config: runtime.config)
    }
    @inlinable
    func block(at hash: C.TBlock.THeader.THasher.THash?,
               runtime: ExtendedRuntime<C>) async throws -> C.TSignedBlock? {
        try await block(at: hash, config: runtime.config)
    }
    @inlinable
    func block(header hash: C.TBlock.THeader.THasher.THash?,
               runtime: ExtendedRuntime<C>) async throws -> C.TBlock.THeader? {
        try await block(header: hash, config: runtime.config)
    }
}