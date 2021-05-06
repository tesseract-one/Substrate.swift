//
//  Substrate.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import SubstrateRpc

public protocol SubstrateProtocol: AnyObject {
    associatedtype R: Runtime
    associatedtype C: RpcClient
    
    // Dependencies
    var client: C { get }
    var registry: TypeRegistryProtocol { get }
    var signer: Optional<SubstrateSigner> { get set }
    
    // Chain properties
    var genesisHash: R.THash { get }
    var runtimeVersion: RuntimeVersion { get }
    var properties: SystemProperties { get }
    
    // Default settings
    var pageSize: UInt { get set }
    var callTimeout: TimeInterval { get set }
    
    // API objects
    var rpc: SubstrateRpcApiRegistry<Self> { get }
    var query: SubstrateStorageApiRegistry<Self> { get }
    var consts: SubstrateConstantApiRegistry<Self> { get }
    var tx: SubstrateExtrinsicApiRegistry<Self> { get }
}

public final class Substrate<R: Runtime, C: RpcClient>: SubstrateProtocol {
    public let client: C
    public let registry: TypeRegistryProtocol
    public var signer: Optional<SubstrateSigner>
    public let genesisHash: R.THash
    public let runtimeVersion: RuntimeVersion
    public let properties: SystemProperties
    
    public let rpc: SubstrateRpcApiRegistry<Substrate<R, C>>
    public let query: SubstrateStorageApiRegistry<Substrate<R, C>>
    public let consts: SubstrateConstantApiRegistry<Substrate<R, C>>
    public let tx: SubstrateExtrinsicApiRegistry<Substrate<R, C>>
    
    public var pageSize: UInt = 10
    public var callTimeout: TimeInterval = 60
    
    public init(
        registry: TypeRegistryProtocol, genesisHash: R.THash,
        runtimeVersion: RuntimeVersion, properties: SystemProperties,
        client: C, signer: SubstrateSigner?
    ) {
        self.registry = registry
        self.genesisHash = genesisHash
        self.runtimeVersion = runtimeVersion
        self.properties = properties
        self.client = client
        self.rpc = SubstrateRpcApiRegistry()
        self.query = SubstrateStorageApiRegistry()
        self.consts = SubstrateConstantApiRegistry()
        self.tx = SubstrateExtrinsicApiRegistry()
        self.signer = signer
        
        rpc.substrate = self
        query.substrate = self
        consts.substrate = self
        tx.substrate = self
        registry.ss58AddressFormat = properties.ss58Format
    }
    
    deinit {
        if let client = client as? WebSocketRpcClient {
            client.disconnect()
        }
    }
}
