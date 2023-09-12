//
//  ConstantsApi.swift
//  
//
//  Created by Yehor Popovych on 08/06/2023.
//

import Foundation
import ScaleCodec

public protocol ConstantsApi<R> {
    associatedtype R: RootApi
    init(api: R)
}

extension ConstantsApi {
    public static var id: ObjectIdentifier { ObjectIdentifier(self) }
}

public enum ConstantsApiError: Error {
    case constantNotFound(name: String, pallet: String)
}

public class ConstantsApiRegistry<R: RootApi>: RootApiAware {
    private let _apis: Synced<[ObjectIdentifier: any ConstantsApi]>
    
    public weak var _rootApi: R!
    
    public init(api: R? = nil) {
        self._rootApi = api
        self._apis = Synced(value: [:])
    }
    
    public func _setRootApi(api: R) {
        self._rootApi = api
    }
    
    public func _api<A>() -> A where A: ConstantsApi, A.R == R {
        _apis.mutate { apis in
            if let api = apis[A.id] as? A {
                return api
            }
            let api = A(api: self._rootApi)
            apis[A.id] = api
            return api
        }
    }
    
    @inlinable
    public func _api<A>(_ t: A.Type) -> A where A: ConstantsApi, A.R == R {
        _api()
    }
}

public extension ConstantsApiRegistry {
    func get<V: RuntimeDynamicDecodable>(name: String, pallet: String) throws -> V {
        guard let ct = _rootApi.runtime.resolve(constant: name, pallet: pallet) else {
            throw ConstantsApiError.constantNotFound(name: name, pallet: pallet)
        }
        return try _rootApi.runtime.decode(from: ct.value) { ct.type }
    }
    
    @inlinable
    func get<V: RuntimeDynamicDecodable>(_ type: V.Type, name: String, pallet: String) throws -> V {
        try get(name: name, pallet: pallet)
    }
    
    func get<C: StaticConstant>(_ type: C.Type) throws -> C.TValue {
        guard let ct = _rootApi.runtime.resolve(constant: type.name, pallet: type.pallet) else {
            throw ConstantsApiError.constantNotFound(name: type.name, pallet: type.pallet)
        }
        var decoder = _rootApi.runtime.decoder(with: ct.value)
        return try type.decode(valueFrom: &decoder, runtime: _rootApi.runtime)
    }
    
    @inlinable
    func `dynamic`(name: String, pallet: String) throws -> Value<TypeDefinition> {
        try get(name: name, pallet: pallet)
    }
}
