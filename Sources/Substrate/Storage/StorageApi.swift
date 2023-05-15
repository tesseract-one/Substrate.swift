//
//  StorageAoi.swift
//  
//
//  Created by Yehor Popovych on 15/05/2023.
//

import Foundation
import ScaleCodec
import JsonRPC
import Serializable
#if !COCOAPODS
import JsonRPCSerializable
#endif

public protocol SrotageApi<S> {
    associatedtype S: SomeSubstrate
    
    static var id: String { get }
    
    var substrate: S! { get }
    
    init(substrate: S) async
}

extension SrotageApi {
    public static var id: String { String(describing: self) }
}

public class StorageApiRegistry<S: SomeSubstrate> {
    private actor Registry {
        private var _apis: [String: any SrotageApi] = [:]
        public func getApi<A, S: SomeSubstrate>(substrate: S) async -> A
            where A: SrotageApi, A.S == S
        {
            if let api = _apis[A.id] as? A {
                return api
            }
            let api = await A(substrate: substrate)
            _apis[A.id] = api
            return api
        }
    }
    private var _apis: Registry
    
    public weak var substrate: S!
    
    public init(substrate: S? = nil) {
        self.substrate = substrate
        self._apis = Registry()
    }
    
    public func setSubstrate(substrate: S) {
        self.substrate = substrate
    }
    
    public func getApi<A>(_ t: A.Type) async -> A where A: SrotageApi, A.S == S {
        await _apis.getApi(substrate: substrate)
    }
}

public extension StorageApiRegistry {
    func storage<K: StorageKey>(key: K, at hash: S.RC.THasher.THash? = nil) async throws -> K.TValue {
        let data = try await substrate.rpc.state.storage(key: key.hash(runtime: substrate.runtime), at: hash)
        return try key.decode(valueFrom: substrate.runtime.decoder(with: data),
                              runtime: substrate.runtime)
    }
    
    func events(at hash: S.RC.THasher.THash? = nil) async throws -> Any {
        let data = try await substrate.rpc.state.storage(
            key: substrate.runtime.eventsStorageKey.hash(runtime: substrate.runtime), at: hash
        )
        return data
    }
}
