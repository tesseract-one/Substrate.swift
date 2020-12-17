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
        let expect = expectation(description: "Simple Request")
        let disconnect = expectation(description: "Disconnect")
        let client = WebSocketRpcClient(url: URL(string: "wss://rpc.polkadot.io")!)
        
        client.onDisconnect = { _, _ in
            disconnect.fulfill()
        }
        
        client.connect()
        
        client.call(method: "chain_getBlock", params: Array<Int>()) { (result: Result<SerializableValue, RpcClientError>) in
            expect.fulfill()
        }
        
        wait(for: [expect], timeout: 10)
        client.disconnect()
        wait(for: [disconnect], timeout: 2)
    }
    
    func testSubscriptionRequest() {
        var index = 0
        let expects = (0...1).map { expectation(description: "Head \($0)")}
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
            print("Subscription", result)
            if index < expects.count {
                expects[index].fulfill()
                index += 1
            } else if (index == expects.count) {
                sub?.unsubscribe()
            }
        }
        
        wait(for: expects, timeout: 20)
        client.disconnect()
        wait(for: [disconnect], timeout: 2)
    }
    
    func testSendPendingRequests() {
        var index = 1
        let expects = (0...2).map { expectation(description: "Expect \($0)")}
        let disconnect = expectation(description: "Disconnect")
        let client = WebSocketRpcClient(url: URL(string: "wss://rpc.polkadot.io")!)
        
        client.onDisconnect = { _, _ in
            disconnect.fulfill()
        }
        
        client.call(method: "chain_getBlock", params: Array<Int>()) { (result: Result<SerializableValue, RpcClientError>) in
            expects[0].fulfill()
        }
        
        var sub: RpcSubscription?
        sub = client.subscribe(
            method: "chain_subscribeFinalizedHeads",
            params: Array<Int>(),
            unsubscribe: "chain_unsubscribeFinalizedHeads"
        ) { (result: Result<SerializableValue, RpcClientError>) in
            print("Subscription", result)
            if index < expects.count {
                expects[index].fulfill()
                index += 1
            } else if (index == expects.count) {
                sub?.unsubscribe()
            }
        }
        
        client.connect()
        
        wait(for: expects, timeout: 20)
        client.disconnect()
        wait(for: [disconnect], timeout: 2)
    }
}
