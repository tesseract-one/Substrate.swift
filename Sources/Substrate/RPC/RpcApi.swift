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

extension RpcApiRegistry: RpcCallableClient where S.CL: RpcCallableClient {
    public func call<Params: Swift.Encodable, Res: Swift.Decodable>(
        method: String, params: Params
    ) async throws -> Res {
        try await substrate.client.call(method: method, params: params)
    }
}

extension RpcApiRegistry: RpcSubscribableClient where S.CL: RpcSubscribableClient {
    public func subscribe<P: Swift.Encodable, E: Swift.Decodable>(
        method: String, params: P, unsubsribe umethod: String
    ) async throws -> AsyncThrowingStream<E, Error> {
        try await substrate.client.subscribe(method: method, params: params, unsubsribe: umethod)
    }
}

public extension RpcApiRegistry where S.CL: RpcCallableClient {
    private struct Methods: Swift.Codable {
        public let methods: Set<String>
    }
    
    func methods() async throws -> Set<String> {
        let methods: Methods = try await call(method: "rpc_methods", params: Params())
        return methods.methods
    }
}
