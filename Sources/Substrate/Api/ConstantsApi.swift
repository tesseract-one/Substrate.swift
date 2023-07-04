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
    var api: R! { get }
    init(api: R)
    static var id: String { get }
}

extension ConstantsApi {
    public static var id: String { String(describing: self) }
}

public enum ConstantsApiError: Error {
    case constantNotFound(name: String, pallet: String)
}

public class ConstantsApiRegistry<R: RootApi> {
    private let _apis: Synced<[String: any ConstantsApi]>
    
    public weak var rootApi: R!
    
    public init(api: R? = nil) {
        self.rootApi = api
        self._apis = Synced(value: [:])
    }
    
    public func setRootApi(api: R) {
        self.rootApi = api
    }
    
    public func getApi<A>(_ t: A.Type) -> A where A: ConstantsApi, A.R == R {
        _apis.sync { apis in
            if let api = apis[A.id] as? A {
                return api
            }
            let api = A(api: self.rootApi)
            apis[A.id] = api
            return api
        }
    }
}

public extension ConstantsApiRegistry {
    func get<V: RuntimeDynamicDecodable>(name: String, pallet: String) throws -> V {
        guard let ct = rootApi.runtime.resolve(constant: name, pallet: pallet) else {
            throw ConstantsApiError.constantNotFound(name: name, pallet: pallet)
        }
        return try rootApi.runtime.decode(from: ct.value, id: ct.type.id)
    }
    
    @inlinable
    func get<V: RuntimeDynamicDecodable>(_ type: V.Type, name: String, pallet: String) throws -> V {
        try get(name: name, pallet: pallet)
    }
    
    func get<C: StaticConstant>(_ type: C.Type) throws -> C.TValue {
        guard let ct = rootApi.runtime.resolve(constant: type.name, pallet: type.pallet) else {
            throw ConstantsApiError.constantNotFound(name: type.name, pallet: type.pallet)
        }
        var decoder = rootApi.runtime.decoder(with: ct.value)
        return try type.decode(valueFrom: &decoder, runtime: rootApi.runtime)
    }
    
    @inlinable
    func `dynamic`(name: String, pallet: String) throws -> Value<RuntimeTypeId> {
        try get(name: name, pallet: pallet)
    }
}

public protocol StaticConstant {
    associatedtype TValue
    
    static var name: String { get }
    static var pallet: String { get }
    
    static func decode<D: ScaleCodec.Decoder>(valueFrom decoder: inout D, runtime: any Runtime) throws -> TValue
}

public extension StaticConstant where TValue: RuntimeDecodable {
    static func decode<D: ScaleCodec.Decoder>(valueFrom decoder: inout D, runtime: any Runtime) throws -> TValue {
        try TValue(from: &decoder, runtime: runtime)
    }
}
