//
//  RpcApi.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation

public protocol RpcApi<R> {
    associatedtype R: RootApi
    var api: R! { get }
    init(api: R)
    static var id: String { get }
}

extension RpcApi {
    public static var id: String { String(describing: self) }
}

public class RpcApiRegistry<R: RootApi>: RootApiAware {
    private let _apis: Synced<[String: any RpcApi]>
    
    public weak var rootApi: R!
    
    public init(api: R? = nil) {
        self.rootApi = api
        self._apis = Synced(value: [:])
    }
    
    public func setRootApi(api: R) {
        self.rootApi = api
    }
    
    public func getApi<A>(_ t: A.Type) -> A where A: RpcApi, A.R == R {
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
