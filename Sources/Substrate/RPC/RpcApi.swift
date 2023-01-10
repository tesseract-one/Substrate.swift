//
//  RpcApi.swift
//  
//
//  Created by Yehor Popovych on 1/11/21.
//

import Foundation
import ScaleCodec
import JsonRPC
#if !COCOAPODS
import JsonRPCSerializable
#endif

public protocol RpcApi {
    associatedtype S: AnySubstrate
    
    static var id: String { get }
    
    var substrate: S! { get }
    
    init(substrate: S) async
}

extension RpcApi {
    public static var id: String { String(describing: self) }
}

public actor RpcApiRegistry<S: AnySubstrate>: CallableClient {    
    private var _apis: [String: Any] = [:]
    public weak var substrate: S!
    
    public func setSubstrate(substrate: S) async {
        self.substrate = substrate
    }
    
    public func getRpcApi<A>(_ t: A.Type) async -> A where A: RpcApi, A.S == S {
        if let api = _apis[t.id] as? A {
            return api
        }
        let api = await t.init(substrate: substrate)
        _apis[t.id] = api
        return api
    }
    
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
