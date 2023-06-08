//
//  RpcClient.swift
//  
//
//  Created by Yehor Popovych on 05.01.2023.
//

import Foundation
import JsonRPC
import Serializable
#if !COCOAPODS
import JsonRPCSerializable
#endif

public class JsonRpcCallableClient: RpcCallableClient, RuntimeHolder {
    public private (set) var client: JsonRPC.Client & ContentCodersProvider
    
    public init(client: JsonRPC.Client & ContentCodersProvider) {
        self.client = client
        if let connectable = self.client as? Connectable {
            connectable.connect()
        }
    }
    
    public func call<Params: Encodable, Res: Decodable>(
        method: String, params: Params
    ) async throws -> Res {
        try await client.call(method: method, params: params)
    }
    
    public var runtime: any Runtime {
       self.client.contentEncoder.runtime
    }
    
    public func setRuntime(runtime: any Runtime) throws {
        self.client.contentEncoder.runtime = runtime
        self.client.contentDecoder.runtime = runtime
    }
    
    deinit {
        if let connectable = self.client as? Connectable {
            connectable.disconnect()
        }
    }
}

public protocol JsonRpcClientDelegate: AnyObject {
    func rpcClientStateUpdated(client: JsonRpcSubscribableClient, state: ConnectableState)
    func rpcClientSubscriptionError(client: JsonRpcSubscribableClient, error: JsonRpcSubscribableClient.Error)
}

public extension JsonRpcClientDelegate {
    func rpcClientStateUpdated(client: JsonRpcSubscribableClient, state: ConnectableState) {}
    func rpcClientSubscriptionError(client: JsonRpcSubscribableClient, error: JsonRpcSubscribableClient.Error) {}
}

public class JsonRpcSubscribableClient: JsonRpcCallableClient, NotificationDelegate, ErrorDelegate, ConnectableDelegate {
    public enum Error: Swift.Error {
        case codec(CodecError)
        case request(RequestError<[CallParam], SerializableValue>)
        case unknown(subscription: String)
        case unsubscribeFailed
        case disconnected
        case duplicate(id: String)
        case empty
        
        public static func from(service error: ServiceError) -> Self {
            .request(.service(error: error))
        }
        
        public static func from(any error: Swift.Error) -> Self {
            switch error {
            case let err as Self: return err
            case let err as ServiceError: return .from(service: err)
            case let err as RequestError<[CallParam], SerializableValue>: return .request(err)
            case let err as CodecError: return .codec(err)
            default: fatalError("Unknown type of error: \(error)")
            }
        }
    }
    
    private struct RpcSubscriptionHeader: Decodable {
        let subscription: String
    }
    
    private struct RpcSubscriptionFull<E: Decodable>: Decodable {
        let subscription: String
        let result: E
    }
    
    private actor Subscriptions {
        private var subscriptions: [String: (Result<Parsable, Error>) -> Void] = [:]
        
        func add(id: String, cb: @escaping (Result<Parsable, Error>) -> Void) throws {
            guard subscriptions[id] == nil else { throw Error.duplicate(id: id) }
            subscriptions[id] = cb
        }
        
        func call(id: String, with res: Result<Parsable, Error>) throws {
            guard let cb = subscriptions[id] else { throw Error.unknown(subscription: id) }
            cb(res)
        }
        
        func remove(id: String) throws {
            guard subscriptions.removeValue(forKey: id) != nil else {
                throw Error.unknown(subscription: id)
            }
        }
        
        func clear() -> [String: (Result<Parsable, Error>) -> Void] {
            defer { subscriptions = [:] }
            return subscriptions
        }
    }
    
    public weak var delegate: JsonRpcClientDelegate?
    private var subscriptions: Subscriptions
    
    public init(client: JsonRPC.Client & Persistent & ContentCodersProvider,
                delegate: JsonRpcClientDelegate?)
    {
        self.subscriptions = Subscriptions()
        super.init(client: client)
        client.delegate = self
    }
    
    public func subscribe<P, E>(
        method: String, params: P, unsubsribe umethod: String
    ) async throws -> AsyncThrowingStream<E, Swift.Error> where P : Encodable, E : Decodable {
        let subscriptionId: String = try await client.call(method: method, params: params)
        return AsyncThrowingStream { continuation in
            let unsubscribe = { [weak self] in
                guard let this = self else { return }
                Task {
                    do {
                        try await this.unsubscribe(id: subscriptionId, method: umethod)
                    } catch {
                        this.onError(.from(any: error))
                    }
                }
            }
            continuation.onTermination = { @Sendable _ in unsubscribe() }
            Task {
                do {
                    try await self.subscriptions.add(id: subscriptionId) { result in
                        switch result {
                        case .failure(let err): continuation.finish(throwing: err)
                        case .success(let parsable):
                            switch parsable.parse(to: RpcSubscriptionFull<E>.self) {
                            case .failure(let error):
                                continuation.finish(throwing: Error.codec(error))
                                unsubscribe()
                            case .success(let value):
                                guard let value = value else {
                                    continuation.finish(throwing: Error.empty)
                                    unsubscribe()
                                    return
                                }
                                continuation.yield(value.result)
                            }
                        }
                    }
                } catch {
                    continuation.finish(throwing: error)
                    unsubscribe()
                }
            }
        }
    }
    
    public func notification(method: String, params: Parsable) {
        switch params.parse(to: RpcSubscriptionHeader.self) {
        case .failure(let error): self.onError(.codec(error))
        case .success(let header):
            guard let header = header else {
                self.onError(.empty)
                return
            }
            Task {
                do {
                    try await self.subscriptions.call(id: header.subscription, with: .success(params))
                } catch {
                    self.onError(.from(any: error))
                }
            }
        }
    }
    
    public func error(_ error: ServiceError) {
        self.onError(.from(service: error))
    }
    
    public func state(_ state: ConnectableState) {
        if state == .disconnected || state == .disconnecting {
            Task { await self.cancelSubscriptions(reason: .disconnected) }
        }
        self.delegate?.rpcClientStateUpdated(client: self, state: state)
    }
    
    private func onError(_ error: Error) {
        self.delegate?.rpcClientSubscriptionError(client: self, error: error)
    }
    
    private func unsubscribe(id: String, method: String) async throws {
        try await self.subscriptions.remove(id: id)
        let result: Bool = try await self.client.call(method: method, params: Params(id))
        if !result { throw Error.unsubscribeFailed }
    }
    
    private func cancelSubscriptions(reason: Error) async {
        let subscriptions = await self.subscriptions.clear()
        for (_, cb) in subscriptions {
            cb(.failure(reason))
        }
    }
}

public func JsonRpcClient<Factory: ServiceFactory>(
    _ cfp: ServiceFactoryProvider<Factory>, queue: DispatchQueue = .global(),
    encoder: ContentEncoder = JSONEncoder.substrate,
    decoder: ContentDecoder = JSONDecoder.substrate
) -> JsonRpcCallableClient where Factory.Connection: SingleShotConnection {
    JsonRpcCallableClient(client: JsonRpc(cfp, queue: queue, encoder: encoder, decoder: decoder))
}

public func JsonRpcClient<Factory: ServiceFactory>(
    _ cfp: ServiceFactoryProvider<Factory>, queue: DispatchQueue = .global(),
    encoder: ContentEncoder = JSONEncoder.substrate,
    decoder: ContentDecoder = JSONDecoder.substrate
) -> JsonRpcSubscribableClient where Factory.Connection: PersistentConnection, Factory.Delegate == AnyObject {
    JsonRpcSubscribableClient(client: JsonRpc(cfp, queue: queue, encoder: encoder, decoder: decoder),
                              delegate: nil)
}
