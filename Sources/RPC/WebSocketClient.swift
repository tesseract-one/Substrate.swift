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
    
    public var url: URL { _socket.request.url! }
    public var responseQueue: DispatchQueue
    public var encoder: JSONEncoder
    public var decoder: JSONDecoder
    
    public var reconnectWaitingTimeout: TimeInterval
    public var callTimeout: TimeInterval
    
    public var onConnect: Optional<(Dictionary<String, String>) -> Void>
    public var onDisconnect: Optional<(String, UInt16) -> Void>
    public var onError: Optional<(SubscribableRpcClientError) -> Void>
    
    private let _socket: WebSocket
    private var _isConnected: Bool
    private var _callIndex: UInt32
    private var _requests: Dictionary<UInt32, (cb: DataCallback, started: Date)>
    private var _subscriptions: Dictionary<String, (sub: WebSocketRpcSubscription, cb: DataCallback)>
    private var _pengingRequests: Array<(id: UInt32, body: Data, cb: DataCallback, added: Date)>
    private var _internalQueue: DispatchQueue
    private var _timer: DispatchSourceTimer?
    
    public init(
        url: URL, responseQueue: DispatchQueue = .main, headers: [String: String] = [:],
        encoder: JSONEncoder = .substrate, decoder: JSONDecoder = .substrate
    ) {
        self.responseQueue = responseQueue; self.encoder = encoder; self.decoder = decoder
        
        _callIndex = 0; _requests = [:]; _subscriptions = [:]
        _isConnected = false; _pengingRequests = []
        _internalQueue = DispatchQueue(
            label: "substrate.rpc.websocket.internalQueue",
            target: .global(qos: .default)
        )
        reconnectWaitingTimeout = 40; callTimeout = 60
        onConnect = nil; onDisconnect = nil
        onError = { err in print("[WebSocket] ERROR:", err) } // Default error handler
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for (h, v) in headers {
            request.setValue(v, forHTTPHeaderField: h)
        }
        _socket = WebSocket(request: request)
        _socket.delegate = self
        _socket.callbackQueue = _internalQueue
        _startTimer()
    }
    
    fileprivate func _unsubscribe(subscription: WebSocketRpcSubscription, cb: RpcClientCallback<Bool>? = nil) {
        _internalQueue.async {
            subscription.cancelled = true
            guard subscription.subscribed else { return }
            self._subscriptions.removeValue(forKey: subscription.id)
            let req = JsonRpcRequest(
                id: self._nextId(),
                method: subscription.method.substrateMethod,
                params: [subscription.id]
            )
            self._send(req: req, wait: false) { res in self.responseQueue.async { cb?(res) } }
        }
    }
    
    // Should be callled from internalQueue
    private func _send<Params, Res>(req: JsonRpcRequest<Params>, wait: Bool, response: @escaping RpcClientCallback<Res>)
        where Params: Encodable & Sequence, Res: Decodable
    {
        let id = req.id
        let encoded = _encode(value: req)
        guard case .success(let data) = encoded else {
            if case .failure(let error) = encoded {
                response(.failure(error))
            }
            return
        }
        
        let callback: DataCallback = { [weak self] res in
            guard let sself = self else { return }
            sself._requests.removeValue(forKey: id)
            let result = res
                .flatMap { sself._decode(data: $0, JsonRpcResponse<Res>.self) }
                .flatMap {
                    $0.isError
                        ? .failure(.rpc(error: $0.error!))
                        : .success($0.result!)
                }
            response(result)
        }
        
        if _isConnected {
            _send(id: id, data: data, cb: callback)
        } else if wait {
            _pengingRequests.append((id: id, body: data, cb: callback, added: Date()))
        } else {
            response(.failure(.transport(error: SubscribableRpcClientError.timedout)))
        }
    }
    
    // Should be callled from internalQueue
    private func _send(id: UInt32, data: Data, cb: @escaping DataCallback) {
        _requests[id] = (cb: cb, started: Date())
        _socket.write(data: data)
    }
    
    // Should be callled from internalQueue
    private func _onData(data: Data) {
        switch _decode(data: data, JsonRpcIdHeader.self) {
        case .success(let header):
            if let id = header.id { // Response
                if let req = _requests[id] {
                    req.cb(.success(data))
                } else { // unknown request
                    responseQueue.async {
                        self.onError?(.unknownRequest(id: id))
                    }
                }
            } else { // Event
                switch _decode(data: data, JsonRpcSubscriptionInfo.self) {
                case .success(let info):
                    if let subs = _subscriptions[info.params.subscription] {
                        subs.cb(.success(data))
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
    private func _connected() {
        for req in _pengingRequests {
            _send(id: req.id, data: req.body, cb: req.cb)
        }
        _pengingRequests.removeAll()
    }
    
    // Should be called only on internalQueue
    private func _disconnected(message: String, code: UInt16) {
        for sub in _subscriptions.values {
            sub.sub.cancelled = true
            responseQueue.async {
                sub.cb(.failure(.transport(
                    error: SubscribableRpcClientError.disconnected(message: message, code: code)
                )))
            }
        }
        _subscriptions.removeAll()
        for req in _requests.values {
            req.cb(.failure(.transport(
                error: SubscribableRpcClientError.disconnected(message: message, code: code)
            )))
        }
        _requests.removeAll()
    }
    
    private func _startTimer() {
        _internalQueue.async {
            self._timer?.cancel()
            self._timer = DispatchSource.makeTimerSource(queue: self._internalQueue)
            self._timer?.setEventHandler { [weak self] in
                self?._checkTimeout()
            }
            self._timer?.schedule(deadline: .now(), repeating: 1.0)
            self._timer?.resume()
        }
    }
    
    // Should be callled from internalQueue
    private func _checkTimeout() {
        let now = Date()
        _pengingRequests = _pengingRequests.filter { req in
            if now.timeIntervalSince(req.added) >= self.reconnectWaitingTimeout {
                req.cb(.failure(.transport(error: SubscribableRpcClientError.timedout)))
                return false
            }
            return true
        }
        var outdated = Array<DataCallback>()
        for req in _requests.values {
            if now.timeIntervalSince(req.started) >= callTimeout {
                outdated.append(req.cb)
            }
        }
        for cb in outdated {
            cb(.failure(.transport(error: SubscribableRpcClientError.timedout)))
        }
    }
    
    private func _encode<Req: Encodable>(value: Req) -> Result<Data, RpcClientError> {
        do {
            return try .success(encoder.encode(value))
        } catch let error as EncodingError {
            return .failure(.encoding(error: error))
        } catch {
            return .failure(.unknown(error: error))
        }
    }
    
    private func _decode<Res: Decodable>(data: Data, _ type: Res.Type) -> Result<Res, RpcClientError> {
        do {
            return try .success(decoder.decode(Res.self, from: data))
        } catch let error as DecodingError {
            return .failure(.decoding(error: error))
        } catch {
            return .failure(.unknown(error: error))
        }
    }
    
    // Non thread safe. Never call without queue
    private func _nextId() -> UInt32 {
        _callIndex = _callIndex == UInt32.max ? 1 : _callIndex + 1
        return _callIndex
    }
    
    deinit {
        _timer?.cancel()
        _socket.delegate = nil
        disconnect()
    }
}

extension WebSocketRpcClient: RpcClient {
    public func call<P, R>(method: Method, params: P, response: @escaping RpcClientCallback<R>)
        where P: Encodable & Sequence, R: Decodable
    {
        _internalQueue.async {
            let req = JsonRpcRequest(id: self._nextId(), method: method.substrateMethod, params: params)
            self._send(req: req, wait: true) { result in
                self.responseQueue.async { response(result) }
            }
        }
    }
}

extension WebSocketRpcClient: SubscribableRpcClient {
    public var isConnected: Bool { _isConnected }
    
    public func connect() {
        _socket.connect()
    }
    
    public func disconnect() {
        _socket.disconnect(closeCode: CloseCode.normal.rawValue)
    }
    
    public func subscribe<P, E>(
        method: Method, params: P, unsubscribe: Method, listener: @escaping RpcSubscriptionListener<E>
    ) -> RpcSubscription
        where P: Encodable & Sequence, E: Decodable
    {
        return _internalQueue.sync {
            let id = self._nextId()
            let req = JsonRpcRequest(id: id, method: method.substrateMethod, params: params)
            let subscription = WebSocketRpcSubscription(id: String(id), method: unsubscribe, client: self)
            let handler: DataCallback = { [weak self] result in
                guard let sself = self else { return }
                let parsed = result
                    .flatMap { sself._decode(data: $0, JsonRpcSubscriptionEvent<E>.self)  }
                    .map { $0.params.result }
                sself.responseQueue.async { listener(parsed) }
            }
            self._send(req: req, wait: true) { (result: Result<String, RpcClientError>)  in
                switch result {
                case .success(let subId):
                    subscription.subscribed(id: subId)
                    self._subscriptions[subId] = (subscription, handler)
                    if (subscription.cancelled) { self._unsubscribe(subscription: subscription) }
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
            _isConnected = true
            _connected()
            responseQueue.async { self.onConnect?(headers) }
        case .disconnected(let s, let c):
            _isConnected = false
            _disconnected(message: s, code: c)
            responseQueue.async { self.onDisconnect?(s, c) }
        case .binary(let data):
            _onData(data: data)
        case .text(let str):
            if let data = str.data(using: .utf8) {
                _onData(data: data)
            } else {
                responseQueue.async {
                    self.onError?(.wrongEncoding(value: str))
                }
            }
        case .error(let err):
            _isConnected = false
            _disconnected(message: "Error", code: .max)
            responseQueue.async {
                self.onError?(.transport(error: err))
            }
        case .cancelled:
            _isConnected = false
            _disconnected(message: "Cancelled", code: .max)
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
        client?._unsubscribe(subscription: self, cb: response)
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
