//
//  Substrate.swift
//
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import JsonRPC

public protocol AnySubstrate: AnyObject {
    associatedtype RT: Runtime
    associatedtype CL: CallableClient & RegistryOwner
    
    // Dependencies
    var client: CL { get }
    var types: Registry { get }
    var signer: Optional<Signer> { get set }
    
    // Chain properties
    var genesisHash: RT.THash { get }
    var runtimeVersion: RT.TRuntimeVersion { get }
    var properties: RT.TSystemProperties { get }
    
//    // Default settings
//    var pageSize: UInt { get set }
//    var callTimeout: TimeInterval { get set }
    
//    // API objects
     var rpc: RpcApiRegistry<Self> { get }
//    var query: SubstrateStorageApiRegistry<Self> { get }
//    var consts: SubstrateConstantApiRegistry<Self> { get }
//    var tx: SubstrateExtrinsicApiRegistry<Self> { get }
}

public final class Substrate<R: Runtime, CL: CallableClient & RegistryOwner>: AnySubstrate {
    public typealias RT = R
    public typealias CL = CL
    
    public private(set) var client: CL
    public let types: Registry
    public var signer: Signer?

    public let genesisHash: RT.THash
    public let runtimeVersion: RT.TRuntimeVersion
    public let properties: RT.TSystemProperties
    
    public let rpc: RpcApiRegistry<Substrate<R, CL>>
    
    public init(client: CL, signer: Signer? = nil) async throws {
        self.signer = signer
        self.client = client
        
        // Obtain initial data from the RPC
        self.runtimeVersion = try await RpcStateApi<Self>.runtimeVersion(at: nil, with: client)
        self.properties = try await RpcSystemApi<Self>.properties(with: client)
        self.genesisHash = try await RpcChainApi<Self>.blockHash(block: .firstBlock, client: client)
        
        let metadata = try await RpcStateApi<Self>.metadata(with: client)
        
        self.types = try DynamicTypeRegistry(metadata: metadata, addressFormat: self.properties.ss58Format)
        self.client.registry = self.types
        
        // Init registries
        self.rpc = RpcApiRegistry()
        
        // Pass substrate to them
        await rpc.setSubstrate(substrate: self)
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
