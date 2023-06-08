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
    
    func accountNextIndex(id: C.TAccountId) async throws -> C.TIndex
    func runtimeVersion(at hash: C.TBlock.THeader.THasher.THash?) async throws -> C.TRuntimeVersion
    func metadata(at hash: C.TBlock.THeader.THasher.THash?) async throws -> Metadata
    func systemProperties() async throws -> C.TSystemProperties
    func block(hash index: C.TBlock.THeader.TNumber?) async throws -> C.TBlock.THeader.THasher.THash?
    func block(at hash: C.TBlock.THeader.THasher.THash?) async throws -> C.TSignedBlock?
    func block(header hash: C.TBlock.THeader.THasher.THash?) async throws -> C.TBlock.THeader?
    func events(
        at hash: C.THasher.THash?,
        runtime: ExtendedRuntime<C>
    ) async throws -> C.TBlockEvents?
    func dryRun<CL: Call>(
        extrinsic: SignedExtrinsic<CL, C.TExtrinsicManager>,
        at hash: C.TBlock.THeader.THasher.THash?,
        manager: C.TExtrinsicManager
    ) async throws -> RpcResult<RpcResult<(), C.TDispatchError>, C.TTransactionValidityError>
    func execute<CL: StaticCodableRuntimeCall>(call: CL,
                                               at hash: C.THasher.THash?) async throws -> CL.TReturn
    func execute<CL: RuntimeCall>(call: CL,
                                  at hash: C.THasher.THash?) async throws -> CL.TReturn
    func submit<CL: Call>(
        extrinsic: SignedExtrinsic<CL, C.TExtrinsicManager>,
        manager: C.TExtrinsicManager
    ) async throws -> C.THasher.THash
}

public protocol SubscribableClient<C>: Client {
    func submitAndWatch<CL: Call>(
        extrinsic: SignedExtrinsic<CL, C.TExtrinsicManager>,
        manager: C.TExtrinsicManager
    ) async throws -> AsyncThrowingStream<C.TTransactionStatus, Error>
}
