//
//  RpcApi.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import ScaleCodec
import JsonRPC
import Serializable
#if !COCOAPODS
import JsonRPCSerializable
#endif

public protocol RuntimeApi<S> {
    associatedtype S: SomeSubstrate
    
    static var id: String { get }
    
    var substrate: S! { get }
    
    init(substrate: S) async
}

extension RuntimeApi {
    public static var id: String { String(describing: self) }
}

public class RuntimeApiRegistry<S: SomeSubstrate> {
    private actor Registry {
        private var _apis: [String: any RuntimeApi] = [:]
        public func getApi<A, S: SomeSubstrate>(substrate: S) async -> A
            where A: RuntimeApi, A.S == S
        {
            if let api = _apis[A.id] as? A {
                return api
            }
            let api = await A(substrate: substrate)
            _apis[A.id] = api
            return api
        }
    }
    private var _apis: Registry
    
    public weak var substrate: S!
    
    public init(substrate: S? = nil) {
        self.substrate = substrate
        self._apis = Registry()
    }
    
    public func setSubstrate(substrate: S) {
        self.substrate = substrate
    }
    
    public func getApi<A>(_ t: A.Type) async -> A where A: RuntimeApi, A.S == S {
        await _apis.getApi(substrate: substrate)
    }
}

public extension RuntimeApiRegistry {
    func execute<C: RuntimeCall>(call: C,
                                 at hash: S.RC.THasher.THash? = nil) async throws -> C.TReturn {
        try await substrate.client.execute(call: call, at: hash)
    }
}
