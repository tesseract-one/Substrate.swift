//
//  RpcApi.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation

public protocol RpcApi<S> {
    associatedtype S: SomeSubstrate
    var substrate: S! { get }
    init(substrate: S)
    static var id: String { get }
}

extension RpcApi {
    public static var id: String { String(describing: self) }
}

public class RpcApiRegistry<S: SomeSubstrate> {
    private let _apis: Synced<[String: any RpcApi]>
    
    public weak var substrate: S!
    
    public init(substrate: S? = nil) {
        self.substrate = substrate
        self._apis = Synced(value: [:])
    }
    
    public func setSubstrate(substrate: S) {
        self.substrate = substrate
    }
    
    public func getApi<A>(_ t: A.Type) -> A where A: RpcApi, A.S == S {
        _apis.sync { apis in
            if let api = apis[A.id] as? A {
                return api
            }
            let api = A(substrate: substrate)
            apis[A.id] = api
            return api
        }
    }
}
