//
//  Substrate.swift
//
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import JsonRPC

public protocol SomeSubstrate<RC>: AnyObject {
    associatedtype RC: RuntimeConfig
    associatedtype CL: CallableClient & RuntimeHolder
    
    // Dependencies
    var client: CL { get }
    var runtime: ExtendedRuntime<RC> { get }
    var signer: Optional<Signer> { get set }
    
//    // API objects
    var rpc: RpcApiRegistry<Self> { get }
    var call: RuntimeApiRegistry<Self> { get }
//    var query: SubstrateStorageApiRegistry<Self> { get }
//    var consts: SubstrateConstantApiRegistry<Self> { get }
    var tx: ExtrinsicApiRegistry<Self> { get }
}

public final class Substrate<RC: RuntimeConfig, CL: CallableClient & RuntimeHolder>: SomeSubstrate {
    public typealias RC = RC
    public typealias CL = CL
    
    public private(set) var client: CL
    public let runtime: ExtendedRuntime<RC>
    public var signer: Signer?
    
    public let rpc: RpcApiRegistry<Substrate<RC, CL>>
    public let call: RuntimeApiRegistry<Substrate<RC, CL>>
    public let tx: ExtrinsicApiRegistry<Substrate<RC, CL>>
    
    public init(client: CL, runtime: ExtendedRuntime<RC>, signer: Signer? = nil) throws {
        self.signer = signer
        self.client = client
        self.runtime = runtime
        
        // Set runtime for JSON decoders
        try self.client.setRuntime(runtime: runtime)
        
        // Create registries
        self.rpc = RpcApiRegistry()
        self.tx = ExtrinsicApiRegistry()
        self.call = RuntimeApiRegistry()
        
        // Init runtime
        try runtime.setSubstrate(substrate: self)
        
        // Init registries
        rpc.setSubstrate(substrate: self)
        tx.setSubstrate(substrate: self)
        call.setSubstrate(substrate: self)
    }
    
    public convenience init(client: CL, config: RC, signer: Signer? = nil) async throws {
        // Obtain initial data from the RPC
        let runtimeVersion = try await RpcStateApi<Self>.runtimeVersion(at: nil, with: client)
        let properties = try await RpcSystemApi<Self>.properties(with: client)
        let genesisHash = try await RpcChainApi<Self>.blockHash(block: 0, client: client)
        
        let metadata: Metadata
        do {
            metadata = try await RuntimeApiRegistry<Self>.metadata(with: client)
        } catch {
            metadata = try await RpcStateApi<Self>.metadata(with: client)
        }
        let runtime = try ExtendedRuntime(config: config, metadata: metadata,
                                          genesisHash: genesisHash,
                                          version: runtimeVersion,
                                          properties: properties)
        try self.init(client: client, runtime: runtime, signer: signer)
    }
}
