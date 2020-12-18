//
//  WebSocketClientTests.swift
//  
//
//  Created by Yehor Popovych on 10/28/20.
//

import XCTest
import Serializable

#if !COCOAPODS
import SubstrateRpc
#else
import Substrate
#endif

final class WebSocketClientTests: XCTestCase {
    func testSimpleRequest() {
        let disconnect = expectation(description: "Disconnect")
        let client = WebSocketRpcClient(url: URL(string: "wss://rpc.polkadot.io")!)
        
        client.onDisconnect = { _, _ in
            disconnect.fulfill()
        }
        
        client.connect()
        
        client.call(method: "chain_getBlock", params: Array<Int>()) { (result: Result<SerializableValue, RpcClientError>) in
            client.disconnect()
            if case .failure(let err) = result {
                XCTFail("Request error: \(err)")
            }
        }
        
        wait(for: [disconnect], timeout: 10)
    }
    
    func testSubscriptionRequest() {
        var index = 0
        let waitFor = 2
        let disconnect = expectation(description: "Disconnect")
        let client = WebSocketRpcClient(url: URL(string: "wss://rpc.polkadot.io")!)
        
        client.onDisconnect = { _, _ in
            disconnect.fulfill()
        }
        
        client.connect()
        
        var sub: RpcSubscription?
        sub = client.subscribe(
            method: "chain_subscribeFinalizedHeads",
            params: Array<Int>(),
            unsubscribe: "chain_unsubscribeFinalizedHeads"
        ) { (result: Result<SerializableValue, RpcClientError>) in
            index += 1
            if index == waitFor {
                sub?.unsubscribe() { _ in
                    client.disconnect()
                }
            }
            
            if case .failure(let err) = result {
                XCTFail("Request error: \(err)")
            }
        }
        
        wait(for: [disconnect], timeout: 20)
    }
    
    func testSendPendingRequests() {
        var index = 0
        let waitFor = 3
        let disconnect = expectation(description: "Disconnect")
        let client = WebSocketRpcClient(url: URL(string: "wss://rpc.polkadot.io")!)
        
        client.onDisconnect = { _, _ in
            disconnect.fulfill()
        }
        
        client.call(method: "chain_getBlock", params: Array<Int>()) { (result: Result<SerializableValue, RpcClientError>) in
            index += 1
            if index == waitFor {
                client.disconnect()
            }
            
            if case .failure(let err) = result {
                XCTFail("Request error: \(err)")
            }
        }
        
        var sub: RpcSubscription?
        sub = client.subscribe(
            method: "chain_subscribeFinalizedHeads",
            params: Array<Int>(),
            unsubscribe: "chain_unsubscribeFinalizedHeads"
        ) { (result: Result<SerializableValue, RpcClientError>) in
            index += 1
            if index == waitFor {
                sub?.unsubscribe() { _ in
                    client.disconnect()
                }
            }
            
            if case .failure(let err) = result {
                XCTFail("Request error: \(err)")
            }
        }
        
        client.connect()
        
        wait(for: [disconnect], timeout: 20)
    }
}
