//
//  StorageApi.swift
//  
//
//  Created by Yehor Popovych on 2/7/21.
//

import Foundation

public protocol SubstrateStorageApi {
    associatedtype S: SubstrateProtocol
    
    static var id: String { get }
    
    var substrate: S! { get }
    
    init(substrate: S)
}

extension SubstrateStorageApi {
    public static var id: String { String(describing: self) }
    
    public func defaultValue<K: StorageKey>(for key: K) throws -> K.Value {
        try substrate.registry.defaultValue(parsed: key)
    }
    
    public func value<K: StorageKey>(for key: K, _ cb: @escaping SRpcApiCallback<K.Value>) {
        substrate.rpc.state.getStorage(for: key, cb)
    }
}

public final class SubstrateStorageApiRegistry<S: SubstrateProtocol> {
    private var _apis: [String: Any] = [:]
    public internal(set) weak var substrate: S!
    
    public func getStorageApi<A>(_ t: A.Type) -> A where A: SubstrateStorageApi, A.S == S {
        if let api = _apis[A.id] as? A {
            return api
        }
        let api = A(substrate: substrate)
        _apis[A.id] = api
        return api
    }
    
    public func defaultValue<K: StorageKey>(for key: K) throws -> K.Value {
        try substrate.registry.defaultValue(parsed: key)
    }
    
    public func value<K: StorageKey>(for key: K, _ cb: @escaping SRpcApiCallback<K.Value>) {
        substrate.rpc.state.getStorage(for: key, cb)
    }
    
    public func defaultValue(dynamic key: AnyStorageKey) throws -> DValue {
        try substrate.registry.defaultValue(for: key)
    }
    
    public func value(dynamic key: AnyStorageKey, _ cb: @escaping SRpcApiCallback<DValue>) {
        substrate.rpc.state.getStorage(dynamic: key, cb)
    }
}
