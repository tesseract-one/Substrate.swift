//
//  File.swift
//  
//
//  Created by Yehor Popovych on 12/25/20.
//

import XCTest
import ScaleCodec
import JsonRPC
@testable import Substrate

final class SubstrateTests: XCTestCase {
    let client = {
        let cl = JsonRpcClient(.ws(url: URL(string: "wss://westend-rpc.polkadot.io")!))
        cl.debug = true
        return cl
    }()
    var env = Environment()
    
    func testInitialization() {
        runAsyncTest(withTimeout: 30) {
            let _ = try await Substrate(rpc: self.client, config: DynamicRuntime())
        }
    }
    
    func testStorageValueCall() {
        runAsyncTest(withTimeout: 30) {
            let substrate = try await Substrate(rpc: self.client, config: DynamicRuntime())
            let entry = try substrate.query.entry(name: "Events", pallet: "System")
            let value = try await entry.value()
            XCTAssertNotNil(value)
        }
    }
    
    func testBlock() {
        runAsyncTest(withTimeout: 30) {
            let substrate = try await Substrate(rpc: self.client, config: DynamicRuntime())
            let block = try await substrate.client.block(config: substrate.runtime.config)
            XCTAssertNotNil(block)
            print("Block: \(block!)")
        }
    }
    
//    func testTransferTx() {
//        runAsyncTest(withTimeout: 300) {
//            let from = self.env.kpAlice //self.env.randomKeyPair()
//            let toKp = self.env.randomKeyPair(exclude: from)
//            let substrate = try await Substrate(rpc: self.client, config: DynamicRuntime())
//            let to = try toKp.address(in: substrate)
//            let call = try AnyCall(name: "transfer_allow_death",
//                                   pallet: "Balances",
//                                   params: .map([
//                                        ("dest", to.asValue()),
//                                        ("value", .u256(15483812856))
//                                   ])
//            )
//            let tx = try await substrate.tx.new(call)
//            let events = try await tx.signSendAndWatch(signer: from)
//                .waitForFinalized()
//                .success()
//            print("Events: \(events)")
//        }
//    }
}

