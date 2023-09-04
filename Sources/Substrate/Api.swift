//
//  Api.swift
//
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation

public protocol RootApi<RC>: AnyObject {
    associatedtype RC: Config
    associatedtype CL: Client where CL.C == RC
    
    // Dependencies
    var client: CL { get }
    var runtime: ExtendedRuntime<RC> { get }
    var signer: Optional<Signer> { get set }
    
    // API objects
    var rpc: RpcApiRegistry<Self> { get }
    var call: RuntimeCallApiRegistry<Self> { get }
    var query: StorageApiRegistry<Self> { get }
    var constants: ConstantsApiRegistry<Self> { get }
    var tx: ExtrinsicApiRegistry<Self> { get }
}

public extension RootApi {
    @inlinable var hash: ST<RC>.Hash? { runtime.metadataHash }
}

public protocol RootApiAware<RAPI> {
    associatedtype RAPI: RootApi
    var rootApi: RAPI! { get }
    mutating func setRootApi(api: RAPI) throws
}

public final class Api<RC: Config, CL: Client>: RootApi where CL.C == RC {
    public typealias RC = RC
    public typealias CL = CL
    
    public private(set) var client: CL
    public let runtime: ExtendedRuntime<RC>
    public var signer: Signer?
    
    public let rpc: RpcApiRegistry<Api<RC, CL>>
    public let call: RuntimeCallApiRegistry<Api<RC, CL>>
    public let tx: ExtrinsicApiRegistry<Api<RC, CL>>
    public let constants: ConstantsApiRegistry<Api<RC, CL>>
    public let query: StorageApiRegistry<Api<RC, CL>>
    
    public init(client: CL, runtime: ExtendedRuntime<RC>, signer: Signer? = nil) throws {
        self.signer = signer
        self.client = client
        self.runtime = runtime
        
        // Create registries
        self.rpc = RpcApiRegistry()
        self.tx = ExtrinsicApiRegistry()
        self.call = RuntimeCallApiRegistry()
        self.query = StorageApiRegistry()
        self.constants = ConstantsApiRegistry()
        
        // Init registries
        constants.setRootApi(api: self)
        rpc.setRootApi(api: self)
        call.setRootApi(api: self)
        query.setRootApi(api: self)
        tx.setRootApi(api: self)
        
        // Validate
        try runtime.validate()
    }
    
    public convenience init(client: CL, config: RC, signer: Signer? = nil,
                            at hash: ST<RC>.Hash? = nil) async throws {
        // Obtain initial data
        let metadata = try await client.metadata(at: hash, config: config)
        let types = try config.dynamicTypes(metadata: metadata)
        async let runtimeVersion = await client.runtimeVersion(at: hash, metadata: metadata,
                                                               config: config, types: types)
        async let properties = await client.systemProperties(metadata: metadata,
                                                             config: config, types: types)
        async let genesisHash = await client.block(hash: 0, metadata: metadata,
                                                   config: config, types: types)!
        let runtime = try await ExtendedRuntime(config: config,
                                                metadata: metadata,
                                                types: types,
                                                metadataHash: hash,
                                                genesisHash: genesisHash,
                                                version: runtimeVersion,
                                                properties: properties)
        try self.init(client: client, runtime: runtime, signer: signer)
    }
    
    public convenience init<Ext>(client: CL, config: Configs.Registry<RC, Ext>, signer: Signer? = nil,
                                 at hash: ST<RC>.Hash? = nil) async throws
    {
        try await self.init(client: client, config: config.config, signer: signer, at: hash)
    }
    
    public func fork(at hash: ST<RC>.Hash?) async throws -> Api<RC, CL> {
        try await Api(client: client, config: runtime.config, signer: signer, at: hash)
    }
}
