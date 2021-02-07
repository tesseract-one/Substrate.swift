//
//  ExtrinsicApi.swift
//  
//
//  Created by Yehor Popovych on 2/7/21.
//

import Foundation

public protocol SubstrateExtrinsicApi {
    associatedtype S: SubstrateProtocol
    
    static var id: String { get }
    
    var substrate: S! { get }
    
    init(substrate: S)
}

extension SubstrateExtrinsicApi {
    public static var id: String { String(describing: self) }
}

public final class SubstrateExtrinsicApiRegistry<S: SubstrateProtocol> {
    private var _apis: [String: Any] = [:]
    public internal(set) weak var substrate: S!
    
    public func getExtrinsicApi<A>(_ t: A.Type) -> A where A: SubstrateExtrinsicApi, A.S == S {
        if let api = _apis[A.id] as? A {
            return api
        }
        let api = A(substrate: substrate)
        _apis[A.id] = api
        return api
    }
}
