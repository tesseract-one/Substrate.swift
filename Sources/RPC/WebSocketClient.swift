//
//  WebSocketClient.swift
//  
//
//  Created by Yehor Popovych on 10/28/20.
//

import Foundation
import Starscream

public class WebSocketRpcClient {
    private typealias DataCallback = (Result<Data, RpcClientError>) -> Void
    
    public var url: URL { socket.request.url! }
    public var responseQueue: DispatchQueue
    public var encoder: JSONEncoder
    public var decoder: JSONDecoder
    
    public var reconnectWaitingTimeout: TimeInterval {
        didSet { self.updateTimer() }
    }
    
    public var onConnect: Optional<(Dictionary<String, String>) -> Void>
    public var onDisconnect: Optional<(String, UInt16) -> Void>
    public var onError: Optional<(SubscribableRpcClientError) -> Void>
    
    private let socket: WebSocket
    private var connected: Bool
    private var callIndex: UInt32
    private var requests: Dictionary<UInt32, DataCallback>
    private var subscriptions: Dictionary<String, (WebSocketRpcSubscription, DataCallback)>
    private var pengingRequests: Array<(UInt32, Data, Date)>
    private var internalQueue: DispatchQueue
    private var timer: DispatchSourceTimer?
    
    public init(
        url: URL, responseQueue: DispatchQueue = .main, headers: [String: String] = [:],
        encoder: JSONEncoder = .substrate, decoder: JSONDecoder = .substrate
    ) {
        self.responseQueue = responseQueue; self.encoder = encoder; self.decoder = decoder
        
        callIndex = 0; requests = [:]; subscriptions = [:]
        connected = false; pengingRequests = []
        internalQueue = DispatchQueue(
            label: "substrate.rpc.websocket.internalQueue",
            target: .global(qos: .default)
        )
        reconnectWaitingTimeout = 40; onConnect = nil; onDisconnect = nil
        onError = { err in print("[WebSocket] ERROR:", err) } // Default error handler
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for (h, v) in headers {
            request.setValue(v, forHTTPHeaderField: h)
        }
        socket = WebSocket(request: request)
        socket.delegate = self
        socket.callbackQueue = internalQueue
    }
    
    fileprivate func unsubscribe(subscription: WebSocketRpcSubscription, cb: RpcClientCallback<Bool>? = nil) {
        internalQueue.async {
            subscription.cancelled = true
            guard subscription.subscribed else { return }
            self.subscriptions.removeValue(forKey: subscription.id)
            let req = JsonRpcRequest(
                id: self.nextId(),
                method: subscription.method.substrateMethod,
                params: [subscription.id]
            )
            self.send(req: req, wait: false) { res in self.responseQueue.async { cb?(res) } }
        }
    }
    
    // Should be callled from internalQueue
    private func send<Params, Res>(req: JsonRpcRequest<Params>, wait: Bool, response: @escaping RpcClientCallback<Res>)
        where Params: Encodable & Sequence, Res: Decodable
    {
        let id = req.id
        let encoded = encode(value: req)
        guard case .success(let data) = encoded else {
            if case .failure(let error) = encoded {
                response(.failure(error))
            }
            return
        }
        self.requests[id] = { [weak self] res in
            guard let sself = self else { return }
            sself.requests.removeValue(forKey: id)
            let result = res
                .flatMap { sself.decode(data: $0, JsonRpcResponse<Res>.self) }
                .flatMap {
                    $0.isError
                        ? .failure(.rpc(error: $0.error!))
                        : .success($0.result!)
                }
            response(result)
        }
        if self.connected {
            self.socket.write(data: data)
        } else if wait {
            self.pengingRequests.append((id, data, Date()))
        } else {
            self.requests[id]?(.failure(.transport(error: SubscribableRpcClientError.timedout)))
        }
    }
    
    // Should be callled from internalQueue
    private func onData(data: Data) {
        switch decode(data: data, JsonRpcIdHeader.self) {
        case .success(let header):
            if let id = header.id { // Response
                if let req = requests[id] {
                    req(.success(data))
                } else { // unknown request
                    responseQueue.async {
                        self.onError?(.unknownRequest(id: id))
                    }
                }
            } else { // Event
                switch decode(data: data, JsonRpcSubscriptionInfo.self) {
                case .success(let info):
                    if let subs = subscriptions[info.params.subscription] {
                        subs.1(.success(data))
                    } else { // unknown event
                        responseQueue.async {
                            self.onError?(.unknownSubscription(id: info.params.subscription))
                        }
                    }
                case .failure(let err):
                    responseQueue.async {
                        self.onError?(.malformedSubscriptionData(data: data, error: err))
                    }
                }
            }
        case .failure(let err):
            responseQueue.async {
                self.onError?(.malformedMessage(data: data, error: err))
            }
        }
    }
    
    // Should be called only on internalQueue
    private func disconnected(message: String, code: UInt16) {
        for sub in subscriptions.values {
            sub.0.cancelled = true
            
            responseQueue.async {
                sub.1(.failure(.transport(
                    error: SubscribableRpcClientError.disconnected(message: message, code: code)
                )))
            }
        }
        subscriptions.removeAll()
    }
    
    private func updateTimer() {
        internalQueue.async {
            self.timer?.cancel()
            self.timer = DispatchSource.makeTimerSource(queue: self.internalQueue)
            self.timer?.setEventHandler { [weak self] in
                self?.checkTimeout()
            }
            self.timer?.schedule(deadline: .now(), repeating: 5.0)
            self.timer?.resume()
        }
    }
    
    // Should be callled from internalQueue
    private func checkTimeout() {
        var i = 0
        let now = Date()
        while i < pengingRequests.count {
            let req = pengingRequests[i]
            if (now.timeIntervalSince(req.2) >= reconnectWaitingTimeout) {
                pengingRequests.remove(at: i)
                self.requests[req.0]?(.failure(.transport(error: SubscribableRpcClientError.timedout)))
            } else {
                i += 1
            }
        }
    }
    
    private func encode<Req: Encodable>(value: Req) -> Result<Data, RpcClientError> {
        do {
            return try .success(encoder.encode(value))
        } catch let error as EncodingError {
            return .failure(.encoding(error: error))
        } catch {
            return .failure(.unknown(error: error))
        }
    }
    
    private func decode<Res: Decodable>(data: Data, _ type: Res.Type) -> Result<Res, RpcClientError> {
        do {
            return try .success(decoder.decode(Res.self, from: data))
        } catch let error as DecodingError {
            return .failure(.decoding(error: error))
        } catch {
            return .failure(.unknown(error: error))
        }
    }
    
    // Non thread safe. Never call without queue
    private func nextId() -> UInt32 {
        callIndex = callIndex == UInt32.max ? 1 : callIndex + 1
        return callIndex
    }
    
    deinit {
        timer?.cancel()
        socket.delegate = nil
        disconnect()
    }
}

extension WebSocketRpcClient: RpcClient {
    public func call<P, R>(method: Method, params: P, response: @escaping RpcClientCallback<R>)
        where P: Encodable & Sequence, R: Decodable
    {
        internalQueue.async {
            let req = JsonRpcRequest(id: self.nextId(), method: method.substrateMethod, params: params)
            self.send(req: req, wait: true) { result in
                self.responseQueue.async { response(result) }
            }
        }
    }
}

extension WebSocketRpcClient: SubscribableRpcClient {
    public var isConnected: Bool { connected }
    
    public func connect() {
        socket.connect()
    }
    
    public func disconnect() {
        socket.disconnect(closeCode: CloseCode.normal.rawValue)
    }
    
    public func subscribe<P, E>(
        method: Method, params: P, unsubscribe: Method, listener: @escaping RpcSubscriptionListener<E>
    ) -> RpcSubscription
        where P: Encodable & Sequence, E: Decodable
    {
        return internalQueue.sync {
            let id = self.nextId()
            let req = JsonRpcRequest(id: id, method: method.substrateMethod, params: params)
            let subscription = WebSocketRpcSubscription(id: String(id), method: unsubscribe, client: self)
            let handler: DataCallback = { [weak self] result in
                guard let sself = self else { return }
                let parsed = result
                    .flatMap { sself.decode(data: $0, JsonRpcSubscriptionEvent<E>.self)  }
                    .map { $0.params.result }
                sself.responseQueue.async { listener(parsed) }
            }
            self.send(req: req, wait: true) { (result: Result<String, RpcClientError>)  in
                switch result {
                case .success(let subId):
                    subscription.subscribed(id: subId)
                    self.subscriptions[subId] = (subscription, handler)
                    if (subscription.cancelled) { self.unsubscribe(subscription: subscription) }
                case .failure(let err):
                    subscription.cancelled = true
                    self.responseQueue.async { handler(.failure(err)) }
                }
            }
            return subscription
        }
    }
}

extension WebSocketRpcClient: WebSocketDelegate {
    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            connected = true
            for request in pengingRequests {
                socket.write(data: request.1)
            }
            pengingRequests.removeAll()
            responseQueue.async { self.onConnect?(headers) }
        case .disconnected(let s, let c):
            connected = false
            disconnected(message: s, code: c)
            responseQueue.async { self.onDisconnect?(s, c) }
        case .binary(let data):
            onData(data: data)
        case .text(let str):
            if let data = str.data(using: .utf8) {
                onData(data: data)
            } else {
                responseQueue.async {
                    self.onError?(.wrongEncoding(value: str))
                }
            }
        case .error(let err):
            connected = false
            disconnected(message: "Error", code: .max)
            responseQueue.async {
                self.onError?(.transport(error: err))
            }
        case .cancelled:
            connected = false
            disconnected(message: "Cancelled", code: .max)
        default:
            return
        }
    }
}

class WebSocketRpcSubscription: RpcSubscription {
    private(set) var id: String
    let method: Method
    weak var client: WebSocketRpcClient?
    var subscribed: Bool
    var cancelled: Bool
    
    init(id: String, method: Method, client: WebSocketRpcClient) {
        self.id = id; self.method = method; self.client = client
        self.cancelled = false; self.subscribed = false
    }
    
    func subscribed(id: String) {
        subscribed = true
        self.id = id
    }
    
    func unsubscribe() {
        unsubscribe(response: nil)
    }
    
    func unsubscribe(response: RpcClientCallback<Bool>?) {
        client?.unsubscribe(subscription: self, cb: response)
    }
}

private struct JsonRpcIdHeader: Decodable {
    let jsonrpc: String
    let id: UInt32?
}

private struct JsonRpcSubscriptionInfo: Decodable {
    struct Params: Decodable {
        let subscription: String
    }
    let jsonrpc: String
    let params: Params
}
