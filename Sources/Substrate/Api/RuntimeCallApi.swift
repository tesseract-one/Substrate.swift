//
//  RuntimeCallApi.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation

public protocol RuntimeCallApi<R> {
    associatedtype R: RootApi
    var api: R! { get }
    init(api: R)
    static var id: String { get }
}

extension RuntimeCallApi {
    public static var id: String { String(describing: self) }
}

public class RuntimeCallApiRegistry<R: RootApi>: RootApiAware {
    private let _apis: Synced<[String: any RuntimeCallApi]>
    
    public weak var rootApi: R!
    
    public init(api: R? = nil) {
        self.rootApi = api
        self._apis = Synced(value: [:])
    }
    
    public func setRootApi(api: R) {
        self.rootApi = api
    }
    
    public func getApi<A>(_ t: A.Type) -> A where A: RuntimeCallApi, A.R == R {
        _apis.sync { apis in
            if let api = apis[A.id] as? A {
                return api
            }
            let api = A(api: rootApi)
            apis[A.id] = api
            return api
        }
    }
}

public extension RuntimeCallApiRegistry {
    func has(method: String, api: String) -> Bool {
        rootApi.runtime.resolve(runtimeCall: method, api: api) != nil
    }
    
    func has<C: RuntimeCall>(call: C) -> Bool {
        has(method: call.method, api: call.api)
    }
    
    func has<C: StaticRuntimeCall>(call type: C.Type) -> Bool {
        has(method: C.method, api: C.api)
    }
    
    func execute<C: RuntimeCall>(call: C,
                                 at hash: R.RC.THasher.THash? = nil) async throws -> C.TReturn {
        try await rootApi.client.execute(call: call,
                                         at: hash ?? rootApi.hash,
                                         runtime: rootApi.runtime)
    }
}
