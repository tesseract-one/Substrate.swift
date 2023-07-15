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
        let cl = JsonRpcClient(.ws(url: URL(string: "wss://westend-rpc.polkadot.io")!,
                                   maximumMessageSize: 16*1024*1024))
        cl.debug = self.debug
        return cl
    }()
    
    lazy var httpClient = {
        let cl = JsonRpcClient(.http(url: URL(string: "https://westend-rpc.polkadot.io")!))
        cl.debug = self.debug
        return cl
    }()
    
    func testInitialization() {
        runAsyncTest(withTimeout: 30) {
            let _ = try await Api(rpc: self.httpClient, config: .dynamic)
        }
    }
    
    func testStorageValueCall() {
        runAsyncTest(withTimeout: 30) {
            let substrate = try await Api(rpc: self.httpClient, config: .dynamic)
            let entry = try substrate.query.dynamic(name: "Events", pallet: "System")
            let value = try await entry.value()
            XCTAssertNotNil(value)
        }
    }
    
    func testStorageIteration() {
        runAsyncTest(withTimeout: 30) {
            let substrate = try await Api(rpc: self.httpClient, config: .dynamic)
            let activeEra = try await substrate.query.dynamic(name: "ActiveEra", pallet: "Staking").value()!
            let eraIndex = activeEra.map!["index"]!
            let entry = try substrate.query.dynamic(name: "ErasStakers", pallet: "Staking")
            var found = false
            for try await _ in try entry.filter(eraIndex).entries().prefix(2) {
                found = true
            }
            XCTAssert(found)
        }
    }
    
    func testBlock() {
        runAsyncTest(withTimeout: 30) {
            let substrate = try await Api(rpc: self.httpClient, config: .dynamic)
            let block = try await substrate.client.block(runtime: substrate.runtime)
            XCTAssertNotNil(block)
            let _ = try block!.block.extrinsics.parsed()
        }
    }
    
    func testTransferTx() {
        runAsyncTest(withTimeout: 20) {
            let from = self.env.kpAlice //self.env.randomKeyPair()
            let toKp = self.env.randomKeyPair(exclude: [from])
            let substrate = try await Api(rpc: self.httpClient, config: .dynamic)
            let to = try toKp.address(in: substrate)
            let call = AnyCall(name: "transfer_allow_death",
                               pallet: "Balances",
                               params: ["dest": to, "value": 15483812856])
            let tx = try await substrate.tx.new(call)
            let _ = try await tx.signAndSend(signer: from)
        }
    }
    
    func testQueryPaymentInfo() {
        runAsyncTest(withTimeout: 20) {
            let from = self.env.kpAlice //self.env.randomKeyPair()
            let toKp = self.env.randomKeyPair(exclude: [from])
            let substrate = try await Api(rpc: self.httpClient, config: .dynamic)
            let to = try toKp.address(in: substrate)
            let call = AnyCall(name: "transfer_allow_death",
                               pallet: "Balances",
                               params: ["dest": to, "value": 15483812856])
            let tx = try await substrate.tx.new(call)
            let _ = try await tx.paymentInfo(account: from.pubKey)
        }
    }
    
    func testQueryFeeDetails() {
        runAsyncTest(withTimeout: 20) {
            let from = self.env.kpAlice //self.env.randomKeyPair()
            let toKp = self.env.randomKeyPair(exclude: [from])
            let substrate = try await Api(rpc: self.httpClient, config: .dynamic)
            let to = try toKp.address(in: substrate)
            let call = AnyCall(name: "transfer_allow_death",
                               pallet: "Balances",
                               params: ["dest": to, "value": 15483812856])
            let tx = try await substrate.tx.new(call)
            let _ = try await tx.feeDetails(account: from.pubKey)
        }
    }
    
    #if !os(Linux) && !os(Windows)
    func testTransferAndWatchTx() {
        runAsyncTest(withTimeout: 300) {
            let from = self.env.kpAlice //self.env.randomKeyPair()
            let toKp = self.env.randomKeyPair(exclude: [from])
            let substrate = try await Api(rpc: self.wsClient, config: .dynamic)
            let to = try toKp.address(in: substrate)
            let call = AnyCall(name: "transfer_allow_death",
                               pallet: "Balances",
                               params: ["dest": to, "value": 15483812850])
            let tx = try await substrate.tx.new(call)
            let events = try await tx.signSendAndWatch(signer: from)
                .waitForFinalized()
                .success()
            XCTAssert(events.events.count > 0)
            print("Events: \(try events.parsed())")
        }
    }
    
    func testTransferAndWatchBatchTx() {
        runAsyncTest(withTimeout: 300) {
            let from = self.env.kpAlice //self.env.randomKeyPair()
            let toKp1 = self.env.randomKeyPair(exclude: [from])
            let toKp2 = self.env.randomKeyPair(exclude: [from, toKp1])
            let substrate = try await Api(rpc: self.wsClient, config: .dynamic)
            let to1 = try toKp1.address(in: substrate)
            let to2 = try toKp2.address(in: substrate)
            let call1 = AnyCall(name: "transfer_allow_death",
                                pallet: "Balances",
                                params: ["dest": to1, "value": 15383812800])
            let call2 = AnyCall(name: "transfer_allow_death",
                                pallet: "Balances",
                                params: ["dest": to2, "value": 15583812810])
            let tx = try await substrate.tx.batchAll([call1, call2])
            let events = try await tx.signSendAndWatch(signer: from)
                .waitForFinalized()
                .success()
            XCTAssert(events.events.count > 0)
            print("Events: \(try events.parsed())")
        }
    }
    #endif
}
