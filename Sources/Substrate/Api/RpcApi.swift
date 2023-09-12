//
//  RpcApi.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation

public protocol RpcApi<R> {
    associatedtype R: RootApi
    init(api: R)
}

extension RpcApi {
    public static var id: ObjectIdentifier { ObjectIdentifier(self) }
}

public class RpcApiRegistry<R: RootApi>: RootApiAware {
    private let _apis: Synced<[ObjectIdentifier: any RpcApi]>
    
    public weak var _rootApi: R!
    
    public init(api: R? = nil) {
        self._rootApi = api
        self._apis = Synced(value: [:])
    }
    
    public func _setRootApi(api: R) {
        self._rootApi = api
    }
    
    public func _api<A>() -> A where A: RpcApi, A.R == R {
        _apis.mutate { apis in
            if let api = apis[A.id] as? A {
                return api
            }
            let api = A(api: _rootApi)
            apis[A.id] = api
            return api
        }
    }
    
    @inlinable
    public func _api<A>(_ t: A.Type) -> A where A: RpcApi, A.R == R {
        _api()
    }
}
