//
//  File.swift
//  
//
//  Created by Yehor Popovych on 12/25/20.
//

import XCTest
import ScaleCodec
import Substrate
#if !COCOAPODS
import SubstrateRPC
#endif

final class SubstrateTests: XCTestCase {
    let debug = false
    lazy var env = Environment()
    
    lazy var wsClient = {
        let cl = JsonRpcClient(.ws(url: URL(string: "wss://westend-rpc.polkadot.io")!))
        cl.debug = self.debug
        return cl
    }()
    
    lazy var httpClient = {
        let cl = JsonRpcClient(.http(url: URL(string: "https://westend-rpc.polkadot.io")!))
        cl.debug = self.debug
        return cl
    }()
    
    func testInitialization() {
        runAsyncTest(withTimeout: 3000) {
            let _ = try await Api(rpc: self.httpClient, config: DynamicConfig())
        }
    }
    
    func testStorageValueCall() {
        runAsyncTest(withTimeout: 30) {
            let substrate = try await Api(rpc: self.httpClient, config: DynamicConfig())
            let entry = try substrate.query.valueEntry(name: "Events", pallet: "System")
            let value = try await entry.value()
            XCTAssertNotNil(value)
        }
    }
    
    func testBlock() {
        runAsyncTest(withTimeout: 30) {
            let substrate = try await Api(rpc: self.httpClient, config: DynamicConfig())
            let block = try await substrate.client.block(config: substrate.runtime.config)
            XCTAssertNotNil(block)
            let _ = try block!.block.extrinsics.parsed()
        }
    }
    
    func testTransferTx() {
        runAsyncTest(withTimeout: 20) {
            let from = self.env.kpAlice //self.env.randomKeyPair()
            let toKp = self.env.randomKeyPair(exclude: from)
            let substrate = try await Api(rpc: self.httpClient, config: DynamicConfig())
            let to = try toKp.address(in: substrate)
            let call = try AnyCall(name: "transfer_allow_death",
                                   pallet: "Balances",
                                   map: ["dest": to, "value": 15483812856])
            let tx = try await substrate.tx.new(call)
            let _ = try await tx.signAndSend(signer: from)
        }
    }
    
    #if !os(Linux) && !os(Windows)
    func testTransferAndWatchTx() {
        runAsyncTest(withTimeout: 300) {
            let from = self.env.kpAlice //self.env.randomKeyPair()
            let toKp = self.env.randomKeyPair(exclude: from)
            let substrate = try await Api(rpc: self.wsClient, config: DynamicConfig())
            let to = try toKp.address(in: substrate)
            let call = try AnyCall(name: "transfer_allow_death",
                                   pallet: "Balances",
                                   map: ["dest": to, "value": 15483812850])
            let tx = try await substrate.tx.new(call)
            let events = try await tx.signSendAndWatch(signer: from)
                .waitForFinalized()
                .success()
            XCTAssert(events.events.count > 0)
            print("Events: \(try events.parsed())")
        }
    }
    #endif
}
