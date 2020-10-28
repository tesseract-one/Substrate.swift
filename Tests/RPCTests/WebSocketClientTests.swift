//
//  WebSocketClientTests.swift
//  
//
//  Created by Yehor Popovych on 10/28/20.
//

import XCTest
import Serializable

#if !COCOAPODS
import RPC
#else
import Substrate
#endif

final class StorageKeyTests: XCTestCase {
    func testSimpleRequest() {
        let expect = expectation(description: "Simple Request")
        let client = WebSocketRpcClient(url: URL(string: "wss://rpc.polkadot.io")!)
        client.connect()
        
        client.call(method: "chain_getBlock", params: Array<Int>()) { (result: Result<SerializableValue, RpcClientError>) in
            expect.fulfill()
        }
        
        wait(for: [expect], timeout: 10)
    }
    
    func testSubscriptionRequest() {
        var index = 0
        let expects = (0...1).map { expectation(description: "Head \($0)")}
        let client = WebSocketRpcClient(url: URL(string: "wss://rpc.polkadot.io")!)
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
    }
    
    func testSendPendingRequests() {
        var index = 1
        let expects = (0...2).map { expectation(description: "Expect \($0)")}
        let client = WebSocketRpcClient(url: URL(string: "wss://rpc.polkadot.io")!)
        
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
    }
}
