//
//  Substrate.swift
//
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import JsonRPC

public protocol AnySubstrate<RC>: AnyObject {
    associatedtype RC: RuntimeConfig
    associatedtype CL: CallableClient & RuntimeHolder
    
    // Dependencies
    var client: CL { get }
    var runtime: ExtendedRuntime<RC> { get }
    var signer: Optional<Signer> { get set }
    
//    // API objects
     var rpc: RpcApiRegistry<Self> { get }
//    var query: SubstrateStorageApiRegistry<Self> { get }
//    var consts: SubstrateConstantApiRegistry<Self> { get }
//    var tx: SubstrateExtrinsicApiRegistry<Self> { get }
}

public final class Substrate<RC: RuntimeConfig, CL: CallableClient & RuntimeHolder>: AnySubstrate {
    public typealias RC = RC
    public typealias CL = CL
    
    public private(set) var client: CL
    public let runtime: ExtendedRuntime<RC>
    public var signer: Signer?
    
    public let rpc: RpcApiRegistry<Substrate<RC, CL>>
    
    public init(client: CL, runtime: ExtendedRuntime<RC>, signer: Signer? = nil) throws {
        self.signer = signer
        self.client = client
        self.runtime = runtime
        
        // Set runtime for JSON decoders
        try self.client.setRuntime(runtime: runtime)
        
        // Create registries
        self.rpc = RpcApiRegistry()
        
        // Init runtime
        try runtime.setSubstrate(substrate: self)
        
        // Init registries
        rpc.setSubstrate(substrate: self)
    }
    
    public convenience init(client: CL, config: RC, signer: Signer? = nil) async throws {
        // Obtain initial data from the RPC
        let runtimeVersion = try await RpcStateApi<Self>.runtimeVersion(at: nil, with: client)
        let properties = try await RpcSystemApi<Self>.properties(with: client)
        let genesisHash = try await RpcChainApi<Self>.blockHash(block: 0, client: client)
        
        let metadata = try await RpcStateApi<Self>.metadata(with: client)
        
        let runtime = try ExtendedRuntime(config: config, metadata: metadata,
                                          genesisHash: genesisHash,
                                          version: runtimeVersion,
                                          properties: properties)
        try self.init(client: client, runtime: runtime, signer: signer)
    }
}

//extension Substrate where CL: SubscribableClient {
//    public convenience init(
//        client: Client & Persistent & ContentCodersProvider,
//        signer: Optional<Signer> = nil
//    ) async throws {
//        try await self.init(client, signer)
//    }
//}
//
//extension Substrate where CT == BasicClient {
//    public convenience init(
//        client: Client & ContentCodersProvider,
//        signer: Optional<Signer> = nil
//    ) async throws {
//        try await self.init(client, signer)
//    }
//}

//public final class Substrate<R: Runtime, C: RpcClient>: SubstrateProtocol {
//    public let client: C
//    public let registry: TypeRegistryProtocol
//    public var signer: Optional<SubstrateSigner>
//    public let genesisHash: R.THash
//    public let runtimeVersion: RuntimeVersion
//    public let properties: SystemProperties
//
//    public let rpc: SubstrateRpcApiRegistry<Substrate<R, C>>
//    public let query: SubstrateStorageApiRegistry<Substrate<R, C>>
//    public let consts: SubstrateConstantApiRegistry<Substrate<R, C>>
//    public let tx: SubstrateExtrinsicApiRegistry<Substrate<R, C>>
//
//    public var pageSize: UInt = 10
//    public var callTimeout: TimeInterval = 60
//
//    public init(
//        registry: TypeRegistryProtocol, genesisHash: R.THash,
//        runtimeVersion: RuntimeVersion, properties: SystemProperties,
//        client: C, signer: SubstrateSigner?
//    ) {
//        var client = client
//        client.parsingContext[.typeRegistry] = registry
//
//        self.registry = registry
//        self.genesisHash = genesisHash
//        self.runtimeVersion = runtimeVersion
//        self.properties = properties
//        self.client = client
//        self.rpc = SubstrateRpcApiRegistry()
//        self.query = SubstrateStorageApiRegistry()
//        self.consts = SubstrateConstantApiRegistry()
//        self.tx = SubstrateExtrinsicApiRegistry()
//        self.signer = signer
//
//        rpc.substrate = self
//        query.substrate = self
//        consts.substrate = self
//        tx.substrate = self
//
//        registry.ss58AddressFormat = properties.ss58Format
//    }
//
//    deinit {
//        if let client = client as? WebSocketRpcClient {
//            client.disconnect()
//        }
//    }
//}
