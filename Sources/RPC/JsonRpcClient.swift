//
//  RpcClient.swift
//  
//
//  Created by Yehor Popovych on 05.01.2023.
//

import Foundation
import JsonRPC
import ContextCodable
import Serializable
import Substrate

public class JsonRpcCallableClient: RpcCallableClient {
    public private (set) var client: JsonRPC.Client & ContentCodersProvider
    
    public var debug: Bool {
        get { client.debug }
        set { client.debug = newValue }
    }
    
    public init(client: JsonRPC.Client & ContentCodersProvider) {
        self.client = client
        if let connectable = self.client as? Connectable {
            connectable.connect()
        }
    }
    
    @inlinable
    public func call<Params: Encodable, Res: Decodable>(
        method: String, params: Params
    ) async throws -> Res {
        try await client.call(method: method, params: params, AnyValue.self)
    }
    
    @inlinable
    public func call<Params: ContextEncodable, Res: Decodable>(
        method: String, params: Params, context: Params.EncodingContext
    ) async throws -> Res {
        try await client.call(method: method, params: params,
                              context: context, AnyValue.self)
    }
    
    @inlinable
    public func call<Params: Encodable, Res: ContextDecodable>(
        method: String, params: Params, context: Res.DecodingContext
    ) async throws -> Res {
        try await client.call(method: method, params: params,
                              context: context, AnyValue.self)
    }
    
    @inlinable
    public func call<Params: ContextEncodable, Res: ContextDecodable>(
        method: String, params: Params,
        encoding econtext: Params.EncodingContext,
        decoding dcontext: Res.DecodingContext
    ) async throws -> Res {
        try await client.call(method: method, params: params,
                              encoding: econtext, decoding: dcontext, AnyValue.self)
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

public class JsonRpcSubscribableClient:
    JsonRpcCallableClient, NotificationDelegate, ErrorDelegate, ConnectableDelegate, RpcSubscribableClient
{
    public enum Error: Swift.Error {
        case codec(CodecError)
        case request(RequestError<Any, AnyValue>)
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
            case let err as TypeErasedRequestError: return .request(err.anyError)
            case let err as CodecError: return .codec(err)
            default: fatalError("Unknown type of error: \(error)")
            }
        }
    }
    
    private struct RpcSubscriptionHeader: Decodable {
        let subscription: String
    }
    
    fileprivate struct RpcSubscriptionFull<E> {
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
        self.delegate = delegate
        super.init(client: client)
        client.delegate = self
    }
    
    public func subscribe<Params: Encodable, Event: Decodable>(
        method: String, params: Params, unsubscribe umethod: String
    ) async throws -> AsyncThrowingStream<Event, Swift.Error> {
        let subscriptionId: String = try await call(method: method, params: params)
        return stream(subscriptionId: subscriptionId, unsubscribe: umethod) {
            $0.parse(to: RpcSubscriptionFull<Event>.self).map { $0?.result }
        }
    }
    
    public func subscribe<Params: ContextEncodable, Event: Decodable>(
        method: String, params: Params, unsubscribe umethod: String, context: Params.EncodingContext
    ) async throws -> AsyncThrowingStream<Event, Swift.Error> {
        let subscriptionId: String = try await call(method: method, params: params, context: context)
        return stream(subscriptionId: subscriptionId, unsubscribe: umethod) {
            $0.parse(to: RpcSubscriptionFull<Event>.self).map { $0?.result }
        }
    }
    
    public func subscribe<Params: Encodable, Event: ContextDecodable>(
        method: String, params: Params, unsubscribe umethod: String, context: Event.DecodingContext
    ) async throws -> AsyncThrowingStream<Event, Swift.Error> {
        let subscriptionId: String = try await call(method: method, params: params)
        return stream(subscriptionId: subscriptionId, unsubscribe: umethod) {
            $0.parse(to: RpcSubscriptionFull<Event>.self, context: context).map { $0?.result }
        }
    }
    
    public func subscribe<Params: ContextEncodable, Event: ContextDecodable>(
        method: String, params: Params, unsubscribe umethod: String,
        encoding econtext: Params.EncodingContext,
        decoding dcontext: Event.DecodingContext
    ) async throws -> AsyncThrowingStream<Event, Swift.Error> {
        let subscriptionId: String = try await call(method: method, params: params, context: econtext)
        return stream(subscriptionId: subscriptionId, unsubscribe: umethod) {
            $0.parse(to: RpcSubscriptionFull<Event>.self, context: dcontext).map { $0?.result }
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
    
    private func stream<Ev>(
        subscriptionId: String, unsubscribe method: String,
        decoder: @escaping (Parsable) -> Result<Ev?, CodecError>
    ) -> AsyncThrowingStream<Ev, Swift.Error> {
        AsyncThrowingStream { continuation in
            let unsubscribe = { [weak self] in
                guard let this = self else { return }
                Task {
                    do {
                        try await this.unsubscribe(id: subscriptionId, method: method)
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
                            switch decoder(parsable) {
                            case .failure(let error):
                                continuation.finish(throwing: Error.codec(error))
                                unsubscribe()
                            case .success(let value):
                                guard let value = value else {
                                    continuation.finish(throwing: Error.empty)
                                    unsubscribe()
                                    return
                                }
                                continuation.yield(value)
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
    
    private func onError(_ error: Error) {
        if debug { print("JsonRpcClient \(self) Global Error: \(error)") }
        self.delegate?.rpcClientSubscriptionError(client: self, error: error)
    }
    
    private func unsubscribe(id: String, method: String) async throws {
        try await self.subscriptions.remove(id: id)
        let result: Bool = try await self.client.call(method: method, params: Params(id),
                                                      AnyValue.self)
        if !result { throw Error.unsubscribeFailed }
    }
    
    private func cancelSubscriptions(reason: Error) async {
        let subscriptions = await self.subscriptions.clear()
        for (_, cb) in subscriptions {
            cb(.failure(reason))
        }
    }
}

extension JsonRpcSubscribableClient.RpcSubscriptionFull: Decodable where E: Decodable {}
extension JsonRpcSubscribableClient.RpcSubscriptionFull: ContextDecodable where E: ContextDecodable {
    typealias DecodingContext = E.DecodingContext
    
    init(from decoder: Decoder, context: DecodingContext) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        subscription = try container.decode(String.self, forKey: .subscription)
        result = try container.decode(E.self, forKey: .result, context: context)
    }
}

public class ErrorLoggerJsonRpcClientDelegate: JsonRpcClientDelegate {
    public init() {}
    public func rpcClientSubscriptionError(
        client: JsonRpcSubscribableClient, error: JsonRpcSubscribableClient.Error
    ) {
        print("JsonRpcClient \(client) Global Error: \(error)")
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
    decoder: ContentDecoder = JSONDecoder.substrate,
    delegate: JsonRpcClientDelegate? = ErrorLoggerJsonRpcClientDelegate()
) -> JsonRpcSubscribableClient where Factory.Connection: PersistentConnection, Factory.Delegate == AnyObject {
    JsonRpcSubscribableClient(client: JsonRpc(cfp, queue: queue, encoder: encoder, decoder: decoder),
                              delegate: delegate)
}

protocol TypeErasedRequestError: Error {
    var anyError: RequestError<Any, AnyValue> { get }
}

extension RequestError: TypeErasedRequestError where Error == AnyValue {
    var anyError: RequestError<Any, AnyValue> {
        switch self {
        case .empty: return .empty
        case .service(error: let err): return .service(error: err)
        case .custom(description: let desc, cause: let cause):
            return .custom(description: desc, cause: cause)
        case .reply(method: let m, params: let p, error: let err):
            return .reply(method: m, params: p, error: err)
        }
    }
}
