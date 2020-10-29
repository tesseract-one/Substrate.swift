//
//  Subscriptions.swift
//  
//
//  Created by Yehor Popovych on 10/28/20.
//

import Foundation

public protocol RpcSubscription {
    func unsubscribe();
    func unsubscribe(response: RpcClientCallback<Bool>?);
}

public typealias RpcSubscriptionListener<Event: Decodable> = (Result<Event, RpcClientError>) -> Void

public enum SubscribableRpcClientError: Error {
    case unknownRequest(id: UInt32)
    case unknownSubscription(id: String)
    case malformedSubscriptionData(data: Data, error: RpcClientError)
    case wrongEncoding(value: String)
    case malformedMessage(data: Data, error: RpcClientError)
    case disconnected(message: String, code: UInt16)
    case transport(error: Error?)
    case timeout
}

public protocol SubscribableRpcClient {
    var isConnected: Bool { get }
    var onConnect: Optional<(Dictionary<String, String>) -> Void> { get set }
    var onDisconnect: Optional<(String, UInt16) -> Void> { get set }
    var onError: Optional<(SubscribableRpcClientError) -> Void> { get set }
    
    func connect()
    func disconnect()
    
    func subscribe<P: Encodable & Sequence, E: Decodable>(
        method: Method, params: P, unsubscribe: Method,
        listener: @escaping RpcSubscriptionListener<E>
    ) -> RpcSubscription
}