//
//  RuntimeCallApi.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation

public protocol RuntimeCallApi<R> {
    associatedtype R: RootApi
    init(api: R)
}

extension RuntimeCallApi {
    public static var id: ObjectIdentifier { ObjectIdentifier(self) }
}

public class RuntimeCallApiRegistry<R: RootApi>: RootApiAware {
    private let _apis: Synced<[ObjectIdentifier: any RuntimeCallApi]>
    
    public weak var _rootApi: R!
    
    public init(api: R? = nil) {
        self._rootApi = api
        self._apis = Synced(value: [:])
    }
    
    public func _setRootApi(api: R) {
        self._rootApi = api
    }
    
    public func _api<A>() -> A where A: RuntimeCallApi, A.R == R {
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
    public func _api<A>(_ t: A.Type) -> A where A: RuntimeCallApi, A.R == R {
        _api()
    }
}

public extension RuntimeCallApiRegistry {
    func has(method: String, api: String) -> Bool {
        _rootApi.runtime.resolve(runtimeCall: method, api: api) != nil
    }
    
    func has<C: RuntimeCall>(call: C) -> Bool {
        has(method: call.method, api: call.api)
    }
    
    func has<C: StaticRuntimeCall>(call type: C.Type) -> Bool {
        has(method: C.method, api: C.api)
    }
    
    func execute<C: RuntimeCall>(call: C,
                                 at hash: ST<R.RC>.Hash? = nil) async throws -> C.TReturn {
        try await _rootApi.client.execute(call: call,
                                          at: hash ?? _rootApi.hash,
                                          runtime: _rootApi.runtime)
    }
}
