//
//  StorageAoi.swift
//  
//
//  Created by Yehor Popovych on 15/05/2023.
//

import Foundation

public protocol StorageApi<R> {
    associatedtype R: RootApi
    var api: R! { get }
    init(api: R)
    static var id: String { get }
}

extension StorageApi {
    public static var id: String { String(describing: self) }
}

public class StorageApiRegistry<R: RootApi>: RootApiAware {
    private let _apis: Synced<[String: any StorageApi]>

    public weak var rootApi: R!
    
    public init(api: R? = nil) {
        self.rootApi = api
        self._apis = Synced(value: [:])
    }
    
    @inlinable
    public func setRootApi(api: R) {
        self.rootApi = api
    }
    
    public func getApi<A>(_ t: A.Type) -> A where A: StorageApi, A.R == R {
        _apis.mutate { apis in
            if let api = apis[A.id] as? A {
                return api
            }
            let api = A(api: rootApi)
            apis[A.id] = api
            return api
        }
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
        try StorageEntry(api: rootApi, params: (name, pallet))
    }
    
    @inlinable
    func `dynamic`(
        name: String, pallet: String
    ) throws -> StorageEntry<R, AnyValueStorageKey> {
        try entry(name: name, pallet: pallet)
    }
    
    @inlinable
    func entry<Key: StaticStorageKey>() throws -> StorageEntry<R, Key> {
        try StorageEntry(api: rootApi, params: ())
    }
    
    @inlinable
    func entry<Key: StaticStorageKey>(_ type: Key.Type) throws -> StorageEntry<R, Key> {
        try StorageEntry(api: rootApi, params: ())
    }
    
    @inlinable
    func changes(
        keys: [any StorageKey],
        at hash: ST<R.RC>.Hash? = nil
    ) async throws -> [(block: ST<R.RC>.Hash, changes: [(key: any StorageKey, value: Any?)])] {
        try await rootApi.client.storage(anychanges: keys,
                                         at: hash ?? rootApi.hash,
                                         runtime: rootApi.runtime)
    }
}

public extension StorageApiRegistry where R.CL: SubscribableClient {
    @inlinable
    func watch(keys: [any StorageKey]) async throws -> AsyncThrowingStream<(any StorageKey, Any?), Error> {
        try await rootApi.client.subscribe(anystorage: keys, runtime: rootApi.runtime)
    }
}
