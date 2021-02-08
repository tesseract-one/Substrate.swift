//
//  ConstantsApi.swift
//  
//
//  Created by Yehor Popovych on 2/7/21.
//

import Foundation

public protocol SubstrateConstantApi {
    associatedtype S: SubstrateProtocol
    
    static var id: String { get }
    
    var substrate: S! { get }
    
    init(substrate: S)
}

extension SubstrateConstantApi {
    public static var id: String { String(describing: self) }
    
    public func value<C: Constant>(for constant: C) throws -> C.Value {
        try substrate.registry.value(of: constant)
    }
}

public final class SubstrateConstantApiRegistry<S: SubstrateProtocol> {
    private var _apis: [String: Any] = [:]
    public internal(set) weak var substrate: S!
    
    public func getConstantApi<A>(_ t: A.Type) -> A where A: SubstrateConstantApi, A.S == S {
        if let api = _apis[A.id] as? A {
            return api
        }
        let api = A(substrate: substrate)
        _apis[A.id] = api
        return api
    }
    
    public func value<C: Constant>(for constant: C) throws -> C.Value {
        try substrate.registry.value(of: constant)
    }
    
    public func value<C: DynamicConstant>(for constant: C) throws -> DValue {
        try substrate.registry.value(of: constant)
    }
}
