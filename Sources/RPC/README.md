# Substrate RPC

## JSON-RPC library for substrate API

## Getting started

### HTTP Client
Simple `URLSession` based JSON-RPC client with message serialization and deserealization. Doesn't support subscriptions.

#### Usage
```swift
let client = HttpRpcClient(url: URL(string: "https://rpc.polkadot.io")!)

// Call with default timeout. Response type will be determined by callback closure type.
client.call(method: "chain_getBlockHash", params: [1]) { (result: Result<String, RpcClientError>) in
    print("Block 1 hash request result is: \(result)")
}

// Call with timeout (in seconds).
client.call(method: "chain_getBlockHash", params: [2], timeout: 20) { (result: Result<String, RpcClientError>) in
    print("Block 2 hash request result is: \(result)")
}
```
Client will wrap request parameters into JSON-RPC message and serialize it. The same will be done to response.

#### Additional constructor parameters

* responseQueue: `DispatchQueue` - queue can be passed to the constructor of  `HttpClient`. All response callbacks will be called on this queue.
* headers: `[String: String]` - request headers. They will be added to each HTTP request. Can be used for authorization.
* session: `URLSession` - custom session to work on. By default is a shared session.
* encoder: `JSONEncoder` - encoder to use for message encoding. By default is special one preconfigured for Substrate.
* decoder: `JSONDecoder` - decoder to use for message decoding. By default is special one preconfigured for Substrate.

### WebSocket Client
Custom WebSocket based JSON-RPC client with message serialization and deserealization. Supports subscriptions.

#### Usage

#### Calls
```swift
let client = WebSocketRpcClient(url: URL(string: "wss://rpc.polkadot.io")!)

// Connect to the server first
client.connect()

// Call with default timeout. Response type will be determined by callback closure type.
client.call(method: "chain_getBlockHash", params: [1]) { (result: Result<String, RpcClientError>) in
    print("Block 1 hash request result is: \(result)")
}

// Call with timeout (in seconds).
client.call(method: "chain_getBlockHash", params: [2], timeout: 20) { (result: Result<String, RpcClientError>) in
    print("Block 2 hash request result is: \(result)")
}

// Disconnect when non-needed. Also will disconnect on client object destruction
client.disconnect()
```

#### Subscriptions
```swift
let client = WebSocketRpcClient(url: URL(string: "wss://rpc.polkadot.io")!)

// Connect to the server first
client.connect()

// Subscribe method will return subscription object. It should be used for unsubscribing.
let subscription = client.subscribe(
    method: "chain_subscribeFinalizedHeads",
    params: Array<Int>(),
    unsubscribe: "chain_unsubscribeFinalizedHeads"
) { (result: Result<SerializableValue, RpcClientError>) in
    print("Subscription", result)
}

// Unsubscribe when non needed. Also will unsubscribe automatically on subscription object destruction.
subscription.unsubscribe()

// Disconnect when non-needed. Also will disconnect on client object destruction
client.disconnect()
```

#### Socket Events
```swift
client.onConnect = { client in
  print("Connected")
}

client.onDisconnect = { code, client in
    print("Disconnected: \(code)")
}

client.onError = { error, client in 
  print("Error: \(error)")
}
```

#### Additional constructor parameters

* responseQueue: `DispatchQueue` - all response callbacks and events will be called on this queue.
* headers: `[String: String]` - request headers. They will be added to initial HTTP connection request. Can be used for authorization.
* autoReconnect: `Bool` - true by default. Client will try to reconnect on connection drop. Requests will be queued and sent after reconnection.
* encoder: `JSONEncoder` - encoder to use for message encoding. By default is special one preconfigured for Substrate.
* decoder: `JSONDecoder` - decoder to use for message decoding. By default is special one preconfigured for Substrate.


#### Additional instance parameters

* callReconnectWaitingTimeout: `TimeInterval` - time interval in seconds. Calls will be queued for this amount of time before drop on reconnection event.
* subscriptionCallTimeout:   `TimeInterval` - time interval in seconds. Timeout for subscription calls.
