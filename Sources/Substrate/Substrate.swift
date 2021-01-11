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
    
    var client: RpcClient { get }
    var metadata: Metadata { get }
    var genesisHash: R.Hash { get }
    var runtimeVersion: RuntimeVersion { get }
    var properties: SystemProperties { get }
    
    var pageSize: UInt { get set }
    var callTimeout: TimeInterval { get set }
    
    func getApi<A>(_ t: A.Type) -> A where A: SubstrateApi, A.S == Self
}

public protocol SubscribableSubstrateProtocol: SubstrateProtocol {
    var subscribableClient: SubscribableRpcClient { get }
}

public class SubstrateBase<R: Runtime> {
    fileprivate var _apis: [String: Any] = [:]
    
    public let metadata: Metadata
    public let genesisHash: R.Hash
    public let runtimeVersion: RuntimeVersion
    public let properties: SystemProperties
    
    public var pageSize: UInt = 10
    public var callTimeout: TimeInterval = 60
    
    public init(
        metadata: Metadata, genesisHash: R.Hash, runtimeVersion: RuntimeVersion, properties: SystemProperties
    ) {
        self.metadata = metadata
        self.genesisHash = genesisHash
        self.runtimeVersion = runtimeVersion
        self.properties = properties
    }
}

final public class Substrate<R: Runtime>: SubstrateBase<R>, SubstrateProtocol {
    public let client: RpcClient
    
    public init(
        metadata: Metadata, genesisHash: R.Hash, runtimeVersion: RuntimeVersion,
        properties: SystemProperties, client: RpcClient
    ) {
        self.client = client
        super.init(metadata: metadata, genesisHash: genesisHash, runtimeVersion: runtimeVersion, properties: properties)
    }
    
    public func getApi<A>(_ t: A.Type) -> A where A: SubstrateApi, A.S == Substrate<R> {
        if let api = _apis[A.id] as? A {
            return api
        }
        let api = A(substrate: self)
        _apis[A.id] = api
        return api
    }
}

final public class SubscribableSubstrate<R: Runtime>: SubstrateBase<R>, SubscribableSubstrateProtocol {
    public var client: RpcClient { subscribableClient }
    public let subscribableClient: SubscribableRpcClient
    
    public init(
        metadata: Metadata, genesisHash: R.Hash, runtimeVersion: RuntimeVersion,
        properties: SystemProperties, client: SubscribableRpcClient
    ) {
        self.subscribableClient = client
        super.init(
            metadata: metadata, genesisHash: genesisHash,
            runtimeVersion: runtimeVersion, properties: properties)
    }
    
    public func getApi<A>(_ t: A.Type) -> A where A: SubstrateApi, A.S == SubscribableSubstrate<R> {
        if let api = _apis[A.id] as? A {
            return api
        }
        let api = A(substrate: self)
        _apis[A.id] = api
        return api
    }
}
