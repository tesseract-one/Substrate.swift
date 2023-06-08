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

public protocol RpcApi<S> {
    associatedtype S: SomeSubstrate
    
    static var id: String { get }
    
    var substrate: S! { get }
    
    init(substrate: S) async
}

extension RpcApi {
    public static var id: String { String(describing: self) }
}

public class RpcApiRegistry<S: SomeSubstrate> {
    private actor Registry {
        private var _apis: [String: any RpcApi] = [:]
        public func getApi<A, S: SomeSubstrate>(substrate: S) async -> A
            where A: RpcApi, A.S == S
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
    
    public func getApi<A>(_ t: A.Type) async -> A where A: RpcApi, A.S == S {
        await _apis.getApi(substrate: substrate)
    }
}

extension RpcApiRegistry: CallableClient where S.CL: CallableClient {
    public func call<Params: Encodable, Res: Decodable>(
        method: String, params: Params
    ) async throws -> Res {
        try await substrate.client.call(method: method, params: params)
    }
}

extension RpcApiRegistry: SubscribableClient where S.CL: SubscribableClient {
    public func subscribe<P: Encodable, E: Decodable>(
        method: String, params: P, unsubsribe umethod: String
    ) async throws -> AsyncThrowingStream<E, Error> {
        try await substrate.client.subscribe(method: method, params: params, unsubsribe: umethod)
    }
}

public extension RpcApiRegistry where S.CL: CallableClient {
    private struct Methods: Codable {
        public let methods: Set<String>
    }
    
    func methods() async throws -> Set<String> {
        let methods: Methods = try await call(method: "rpc_methods", params: Params())
        return methods.methods
    }
}
