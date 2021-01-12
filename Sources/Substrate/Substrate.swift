//
//  Substrate.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import SubstrateRpc

public protocol SubstrateProtocol: class {
    associatedtype R: Runtime
    associatedtype C: RpcClient
    
    var client: C { get }
    var registry: TypeRegistryProtocol { get }
    var genesisHash: R.Hash { get }
    var runtimeVersion: RuntimeVersion { get }
    var properties: SystemProperties { get }
    
    var pageSize: UInt { get set }
    var callTimeout: TimeInterval { get set }
    
    func getApi<A>(_ t: A.Type) -> A where A: SubstrateApi, A.S == Self
}

public final class Substrate<R: Runtime, C: RpcClient>: SubstrateProtocol {
    private var _apis: [String: Any] = [:]
    
    public let client: C
    public let registry: TypeRegistryProtocol
    public let genesisHash: R.Hash
    public let runtimeVersion: RuntimeVersion
    public let properties: SystemProperties
    
    public var pageSize: UInt = 10
    public var callTimeout: TimeInterval = 60
    
    public init(
        registry: TypeRegistryProtocol, genesisHash: R.Hash,
        runtimeVersion: RuntimeVersion, properties: SystemProperties,
        client: C
    ) {
        self.registry = registry
        self.genesisHash = genesisHash
        self.runtimeVersion = runtimeVersion
        self.properties = properties
        self.client = client
    }
    
    public func getApi<A>(_ t: A.Type) -> A where A : SubstrateApi, A.S == Substrate<R, C> {
        if let api = _apis[A.id] as? A {
            return api
        }
        let api = A(substrate: self)
        _apis[A.id] = api
        return api
    }
}
