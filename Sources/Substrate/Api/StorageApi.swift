//
//  StorageAoi.swift
//  
//
//  Created by Yehor Popovych on 15/05/2023.
//

import Foundation

public protocol StorageApi<R> {
    associatedtype R: RootApi
    init(api: R)
}

extension StorageApi {
    public static var id: ObjectIdentifier { ObjectIdentifier(self) }
}

public class StorageApiRegistry<R: RootApi>: RootApiAware {
    private let _apis: Synced<[ObjectIdentifier: any StorageApi]>

    public weak var _rootApi: R!
    
    public init(api: R? = nil) {
        self._rootApi = api
        self._apis = Synced(value: [:])
    }
    
    @inlinable
    public func _setRootApi(api: R) {
        self._rootApi = api
    }
    
    public func _api<A>() -> A where A: StorageApi, A.R == R {
        _apis.mutate { apis in
            if let api = apis[A.id] as? A {
                return api
            }
            let api = A(api: _rootApi)
            apis[A.id] = api
            return api
        }
    }
    
    @inlinable
    public func _api<A>(_ t: A.Type) -> A where A: StorageApi, A.R == R {
        _api()
    }
}

public extension StorageApiRegistry {
    @inlinable
    func entry<D: RuntimeDynamicDecodable>(
        name: String, pallet: String
    ) throws -> StorageEntry<R, AnyStorageKey<D>> {
        try entry(D.self, name: name, pallet: pallet)
    }
    
    @inlinable
    func entry<D: RuntimeDynamicDecodable>(
        _ type: D.Type, name: String, pallet: String
    ) throws -> StorageEntry<R, AnyStorageKey<D>> {
        try StorageEntry(api: _rootApi, params: (name, pallet))
    }
    
    @inlinable
    func `dynamic`(
        name: String, pallet: String
    ) throws -> StorageEntry<R, AnyValueStorageKey> {
        try entry(name: name, pallet: pallet)
    }
    
    @inlinable
    func entry<Key: StaticStorageKey>() -> StorageEntry<R, Key> {
        try! StorageEntry(api: _rootApi, params: ())
    }
    
    @inlinable
    func entry<Key: StaticStorageKey>(_ type: Key.Type) -> StorageEntry<R, Key> {
        try! StorageEntry(api: _rootApi, params: ())
    }
    
    @inlinable
    func changes(
        keys: [any StorageKey],
        at hash: ST<R.RC>.Hash? = nil
    ) async throws -> [(block: ST<R.RC>.Hash, changes: [(key: any StorageKey, value: Any?)])] {
        try await _rootApi.client.storage(anychanges: keys,
                                          at: hash ?? _rootApi.hash,
                                          runtime: _rootApi.runtime)
    }
}

public extension StorageApiRegistry where R.CL: SubscribableClient {
    @inlinable
    func watch(keys: [any StorageKey]) async throws -> AsyncThrowingStream<(any StorageKey, Any?), Error> {
        try await _rootApi.client.subscribe(anystorage: keys, runtime: _rootApi.runtime)
    }
}
