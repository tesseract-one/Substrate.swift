//
//  Messages.swift
//  
//
//  Created by Yehor Popovych on 10/27/20.
//

import Foundation

public struct JsonRpcRequest<P: Encodable>: Encodable {
    public let jsonrpc: String = "2.0"
    public let id: UInt32
    public let method: String
    public let params: P
    
    public init(id: UInt32, method: String, params: P) {
        self.id = id; self.method = method; self.params = params
    }
}

public struct JsonRpcError: Decodable, Error, Equatable, Hashable {
    public let code: UInt32
    public let message: String
}

public struct JsonRpcResponse<R: Decodable>: Decodable {
    public let id: UInt32
    public let result: R?
    public let error: JsonRpcError?
    
    public var isError: Bool { error != nil }
}

public struct JsonRpcSubscriptionEvent<Result: Decodable>: Decodable {
    public struct Params: Decodable {
        public let result: Result
        public let subscription: String
    }
    
    public let jsonrpc: String
    public let method: String
    public let params: Params
}
