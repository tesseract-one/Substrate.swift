//
//  StorageAoi.swift
//  
//
//  Created by Yehor Popovych on 15/05/2023.
//

import Foundation

public protocol StorageApi<S> {
    associatedtype S: SomeSubstrate
    var substrate: S! { get }
    init(substrate: S)
    static var id: String { get }
}

extension StorageApi {
    public static var id: String { String(describing: self) }
}

public class StorageApiRegistry<S: SomeSubstrate> {
    private let _apis: Synced<[String: any StorageApi]>

    public weak var substrate: S!
    
    public init(substrate: S? = nil) {
        self.substrate = substrate
        self._apis = Synced(value: [:])
    }
    
    @inlinable
    public func setSubstrate(substrate: S) {
        self.substrate = substrate
    }
    
    public func getApi<A>(_ t: A.Type) -> A where A: StorageApi, A.S == S {
        _apis.sync { apis in
            if let api = apis[A.id] as? A {
                return api
            }
            let api = A(substrate: substrate)
            apis[A.id] = api
            return api
        }
    }
    
    @inlinable
    public func entry(name: String, pallet: String) throws -> StorageEntry<S, AnyStorageKey> {
        try StorageEntry(substrate: substrate, params: (name, pallet))
    }
    
    @inlinable
    public func entry<Key: StaticStorageKey>(_ type: Key.Type) throws -> StorageEntry<S, Key> {
        try StorageEntry(substrate: substrate, params: ())
    }
    
    @inlinable
    public func changes(
        keys: [any StorageKey],
        at hash: S.RC.THasher.THash? = nil
    ) async throws -> [(any StorageKey, Any?)]{
        try await substrate.client.storage(anychanges: keys, at: hash, runtime: substrate.runtime)
    }
}

public extension StorageApiRegistry where S.CL: SubscribableClient {
    @inlinable
    func watch(keys: [any StorageKey]) async throws -> AsyncThrowingStream<(any StorageKey, Any?), Error> {
        try await substrate.client.subscribe(anystorage: keys, runtime: substrate.runtime)
    }
}
