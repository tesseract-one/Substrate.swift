//
//  ConstantsApi.swift
//  
//
//  Created by Yehor Popovych on 08/06/2023.
//

import Foundation

public protocol ConstantsApi<S> {
    associatedtype S: SomeSubstrate
    var substrate: S! { get }
    init(substrate: S)
    static var id: String { get }
}

extension ConstantsApi {
    public static var id: String { String(describing: self) }
}

public enum ConstantsApiError: Error {
    case constantNotFound(name: String, pallet: String)
}

public class ConstantsApiRegistry<S: SomeSubstrate> {
    private let _apis: Synced<[String: any ConstantsApi]>
    
    public weak var substrate: S!
    
    public init(substrate: S? = nil) {
        self.substrate = substrate
        self._apis = Synced(value: [:])
    }
    
    public func setSubstrate(substrate: S) {
        self.substrate = substrate
    }
    
    public func getApi<A>(_ t: A.Type) -> A where A: ConstantsApi, A.S == S {
        _apis.sync { apis in
            if let api = apis[A.id] as? A {
                return api
            }
            let api = A(substrate: self.substrate)
            apis[A.id] = api
            return api
        }
    }
}

public extension ConstantsApiRegistry {
    func get<V: ScaleRuntimeDynamicDecodable>(name: String, pallet: String) throws -> V {
        guard let ct = substrate.runtime.resolve(constant: name, pallet: pallet) else {
            throw ConstantsApiError.constantNotFound(name: name, pallet: pallet)
        }
        return try V(from: substrate.runtime.decoder(with: ct.value),
                     as: ct.type.id,
                     runtime: substrate.runtime)
    }
    
    @inlinable
    func get<V: ScaleRuntimeDynamicDecodable>(_ type: V.Type, name: String, pallet: String) throws -> V {
        try get(name: name, pallet: pallet)
    }
}
