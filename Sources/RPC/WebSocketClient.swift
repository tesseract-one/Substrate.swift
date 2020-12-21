//
//  WebSocketClient.swift
//  
//
//  Created by Yehor Popovych on 10/28/20.
//

import Foundation
import WebSocket

public class WebSocketRpcClient {
    private typealias DataCallback = (Result<Data, RpcClientError>) -> Void
    
    // Connection url. Read only.
    public let url: URL
    // Connection headers. Read only.
    public let headers: Dictionary<String, String>
    // DispatchQueue for callbacks. By default is main queue.
    // This will not block main queue. All operations work on internal queue.
    // Set it if you want to get responses in a different queue.
    public var responseQueue: DispatchQueue
    // JSON Encoder. By default is a special preconfigured one.
    public var encoder: JSONEncoder
    // JSON Decoder. By default is a special preconfigured one.
    public var decoder: JSONDecoder
    
    // Do we need to reconnect on connection failure
    public var autoReconnect: Bool
    // How much to wait for reconnect before cancelling the call.
    public var callReconnectWaitingTimeout: TimeInterval
    // How much to wait for subscription call.
    public var subscriptionCallTimeout: TimeInterval
    
    // Connection event. Dictionary is a list of headers.
    public var onConnect: Optional<(SubscribableRpcClient) -> Void>
    // Disconnect event. Parameters are message and code.
    public var onDisconnect: Optional<(UInt16, SubscribableRpcClient) -> Void>
    // Global Error event.
    // Unhandled or broken messages and socket errors will be sent here.
    // By default will log them to the console. Set to `nil` to remove logs.
    public var onError: Optional<(SubscribableRpcClientError, SubscribableRpcClient) -> Void>
    
    private let _socket: WebSocket
    private var _isConnected: Bool
    private var _disconnecting: Bool
    private var _callIndex: UInt32
    private var _requests: Dictionary<UInt32, (cb: DataCallback, timeout: Date)>
    private var _subscriptions: Dictionary<String, (sub: WebSocketRpcSubscription, cb: DataCallback)>
    private var _pengingRequests: Array<(id: UInt32, body: Data, cb: DataCallback, callTO: TimeInterval, timeout: Date)>
    private var _internalQueue: DispatchQueue
    private var _timer: DispatchSourceTimer?
    
    public init(
        url: URL, responseQueue: DispatchQueue = .main, headers: [String: String] = [:],
        autoReconnect: Bool = true, encoder: JSONEncoder = .substrate, decoder: JSONDecoder = .substrate
    ) {
        self.responseQueue = responseQueue; self.encoder = encoder; self.decoder = decoder
        self.url = url
        
        _callIndex = 0; _requests = [:]; _subscriptions = [:]
        _isConnected = false; _pengingRequests = []
        _internalQueue = DispatchQueue(
            label: "substrate.rpc.websocket.internalQueue",
            target: .global(qos: .default)
        )
        
        callReconnectWaitingTimeout = 40; subscriptionCallTimeout = 10
        self.autoReconnect = autoReconnect
        onConnect = nil; onDisconnect = nil
        onError = { err, client in print("[WebSocket \(client)] ERROR: \(err)") } // Default error handler
        _disconnecting = false
        
        var headers = headers
        headers["Content-Type"] = "application/json"
        headers["Accept"] = "application/json"
        self.headers = headers
        
        _socket = WebSocket(callbackQueue: _internalQueue)
        _socket.pingInterval = .seconds(20)
        _startTimer()
        _addSocketHandlers()
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
            self._send(req: req, wait: false, timeout: self.subscriptionCallTimeout) { res in
                self.responseQueue.async { cb?(res) }
            }
        }
    }
    
    // Should be callled from internalQueue
    private func _send<Params, Res>(req: JsonRpcRequest<Params>, wait: Bool, timeout: TimeInterval, response: @escaping RpcClientCallback<Res>)
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
            _send(id: id, data: data, timeout: timeout, cb: callback)
        } else if wait {
            let timeoutDate = Date(timeIntervalSinceNow: callReconnectWaitingTimeout)
            _pengingRequests.append((id: id, body: data, cb: callback, callTO: timeout, timeout: timeoutDate))
        } else {
            response(.failure(.transport(
                error: SubscribableRpcClientError.disconnected(code: .max)
            )))
        }
    }
    
    // Should be callled from internalQueue
    private func _send(id: UInt32, data: Data, timeout: TimeInterval, cb: @escaping DataCallback) {
        let timeoutDate = Date(timeIntervalSinceNow: timeout)
        _requests[id] = (cb: cb, timeout: timeoutDate)
        _socket.send(data)
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
                        self.onError?(.unknownRequest(id: id), self)
                    }
                }
            } else { // Event
                switch _decode(data: data, JsonRpcSubscriptionInfo.self) {
                case .success(let info):
                    if let subs = _subscriptions[info.params.subscription] {
                        subs.cb(.success(data))
                    } else { // unknown event
                        responseQueue.async {
                            self.onError?(.unknownSubscription(id: info.params.subscription), self)
                        }
                    }
                case .failure(let err):
                    responseQueue.async {
                        self.onError?(.malformedSubscriptionData(data: data, error: err), self)
                    }
                }
            }
        case .failure(let err):
            responseQueue.async {
                self.onError?(.malformedMessage(data: data, error: err), self)
            }
        }
    }
    
    // Should be called only on internalQueue
    private func _connected() {
        for req in _pengingRequests {
            _send(id: req.id, data: req.body, timeout: req.callTO, cb: req.cb)
        }
        _pengingRequests.removeAll()
    }
    
    // Should be called only on internalQueue
    private func _disconnected(code: UInt16) {
        for sub in _subscriptions.values {
            sub.sub.cancelled = true
            responseQueue.async {
                sub.cb(.failure(.transport(
                    error: SubscribableRpcClientError.disconnected(code: code)
                )))
            }
        }
        _subscriptions.removeAll()
        for req in _requests.values {
            req.cb(.failure(.transport(
                error: SubscribableRpcClientError.disconnected(code: code)
            )))
        }
        _requests.removeAll()
        if autoReconnect && !_disconnecting { connect() } // Reconnecting
        _disconnecting = false
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
            if now >= req.timeout {
                req.cb(.failure(.transport(error: SubscribableRpcClientError.timeout)))
                return false
            }
            return true
        }
        var outdated = Array<DataCallback>()
        outdated.reserveCapacity(_requests.count / 2)
        for req in _requests.values {
            if now >= req.timeout {
                outdated.append(req.cb)
            }
        }
        for cb in outdated {
            cb(.failure(.transport(error: SubscribableRpcClientError.timeout)))
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
        _socket.disconnect()
    }
}

extension WebSocketRpcClient: RpcClient {
    public func call<P, R>(method: Method, params: P, timeout: TimeInterval = 60, response: @escaping RpcClientCallback<R>)
        where P: Encodable & Sequence, R: Decodable
    {
        _internalQueue.async {
            let req = JsonRpcRequest(id: self._nextId(), method: method.substrateMethod, params: params)
            self._send(req: req, wait: true, timeout: timeout) { result in
                self.responseQueue.async { response(result) }
            }
        }
    }
}

extension WebSocketRpcClient: SubscribableRpcClient {
    public var isConnected: Bool { _isConnected }
    
    public func connect() {
        let headers = self.headers.map{($0, $1)}
        _socket.connect(url: url, headers: HTTPHeaders(headers))
    }
    
    public func disconnect() {
        _disconnecting = true
        _socket.disconnect()
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
            self._send(req: req, wait: true, timeout: self.subscriptionCallTimeout) { (result: Result<String, RpcClientError>)  in
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


extension WebSocketRpcClient {
    private func _addSocketHandlers() {
        _socket.onConnected = { [weak self] socket in
            guard let sself = self else { return }
            sself._isConnected = true
            sself._connected()
            sself.responseQueue.async { sself.onConnect?(sself) }
        }
        _socket.onDisconnected = { [weak self] code, socket in
            guard let sself = self else { return }
            let c = UInt16(webSocketErrorCode: code)
            sself._isConnected = false
            sself._disconnected(code: c)
            sself.responseQueue.async { sself.onDisconnect?(c, sself) }
        }
        _socket.onData = { [weak self] data, socket in
            guard let sself = self else { return }
            switch data {
            case .binary(let d): sself._onData(data: d)
            case .text(let text):
                if let data = text.data(using: .utf8) {
                    sself._onData(data: data)
                } else {
                    sself.responseQueue.async {
                        sself.onError?(.wrongEncoding(value: text), sself)
                    }
                }
            }
            
        }
        _socket.onError = { [weak self] error, socket in
            guard let sself = self else { return }
            sself._isConnected = false
            sself._disconnected(code: .max)
            sself.responseQueue.async {
                sself.onError?(.transport(error: error), sself)
            }
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
    
    func unsubscribe(response: RpcClientCallback<Bool>? = nil) {
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
