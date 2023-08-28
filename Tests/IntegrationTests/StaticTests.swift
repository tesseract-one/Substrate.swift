//
//  StaticTests.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import XCTest
import ScaleCodec
import Substrate
import SubstrateRPC

final class StaticTests: XCTestCase {
    let debug = false
    lazy var env = Environment()
    
    lazy var wsClient = {
        let cl = JsonRpcClient(.ws(url: env.wsUrl,
                                   maximumMessageSize: 16*1024*1024))
        cl.debug = self.debug
        return cl
    }()
    
    lazy var httpClient = {
        let cl = JsonRpcClient(.http(url: env.httpUrl))
        cl.debug = self.debug
        return cl
    }()
    
    func testInitialization() {
        runAsyncTest(withTimeout: 30) {
            let _ = try await Api(rpc: self.httpClient, config: .substrate)
        }
    }
    
    func testStorageValueCall() {
        runAsyncTest(withTimeout: 30) {
            let substrate = try await Api(rpc: self.httpClient, config: .substrate)
            let entry = try substrate.query.dynamic(name: "Events", pallet: "System")
            let value = try await entry.value()
            XCTAssertNotNil(value)
        }
    }
    
    func testStorageIteration() {
        runAsyncTest(withTimeout: 30) {
            let substrate = try await Api(rpc: self.httpClient, config: .substrate)
            let entry = try substrate.query.dynamic(name: "Account", pallet: "System")
            var found = false
            for try await _ in entry.entries().prefix(2) {
                found = true
            }
            XCTAssert(found)
        }
    }
    
    func testBlock() {
        runAsyncTest(withTimeout: 30) {
            let substrate = try await Api(rpc: self.httpClient, config: .substrate)
            let block = try await substrate.client.block(runtime: substrate.runtime)
            XCTAssertNotNil(block)
            print("Block: \(block!)")
            let _ = try block!.block.extrinsics.parsed()
        }
    }
    
    func testTransferTx() {
        runAsyncTest(withTimeout: 30) {
            let from = self.env.fundedKeyPairs.someElement()!
            let toKp = self.env.keyPairs.someElement(without: [from])!
            let substrate = try await Api(rpc: self.httpClient, config: .substrate)
            let to = try toKp.address(in: substrate)
            let call = AnyCall(name: "transfer_allow_death",
                               pallet: "Balances",
                               params: ["dest": to, "value": 15483812856])
            let tx = try await substrate.tx.new(call)
            let _ = try await tx.signAndSend(signer: from)
        }
    }
    
//    func testTransferBatchTx() {
//        runAsyncTest(withTimeout: 30) {
//            let substrate = try await Api(rpc: self.httpClient, config: .substrate)
//            guard substrate.runtime.isBatchSupported else {
//                print("Batch is not supported in the current runtime")
//                return
//            }
//            let from = self.env.fundedKeyPairs.someElement()!
//            let toKp1 = self.env.keyPairs.someElement(without: [from])!
//            let toKp2 = self.env.keyPairs.someElement(without: [from, toKp1])!
//
//            let to1 = try toKp1.address(in: substrate)
//            let to2 = try toKp2.address(in: substrate)
//            let call1 = AnyCall(name: "transfer_allow_death",
//                                pallet: "Balances",
//                                params: ["dest": to1, "value": 15383812800])
//            let call2 = AnyCall(name: "transfer_allow_death",
//                                pallet: "Balances",
//                                params: ["dest": to2, "value": 15583812810])
//            let tx = try await substrate.tx.batchAll([call1, call2])
//            let _ = try await tx.signAndSend(signer: from)
//        }
//    }
    
    func testQueryPaymentInfo() {
        runAsyncTest(withTimeout: 30) {
            let from = self.env.fundedKeyPairs.someElement()!
            let toKp = self.env.keyPairs.someElement(without: [from])!
            let substrate = try await Api(rpc: self.httpClient, config: .substrate)
            let to = try toKp.address(in: substrate)
            let call = AnyCall(name: "transfer_allow_death",
                               pallet: "Balances",
                               params: ["dest": to, "value": 15483812856])
            let tx = try await substrate.tx.new(call)
            let _ = try await tx.paymentInfo(account: from.pubKey)
        }
    }
    
    func testQueryFeeDetails() {
        runAsyncTest(withTimeout: 30) {
            let from = self.env.fundedKeyPairs.someElement()!
            let toKp = self.env.keyPairs.someElement(without: [from])!
            let substrate = try await Api(rpc: self.httpClient, config: .substrate)
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
            let from = self.env.fundedKeyPairs.someElement()!
            let toKp = self.env.keyPairs.someElement(without: [from])!
            let substrate = try await Api(rpc: self.wsClient, config: .substrate)
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
    
//    func testTransferAndWatchBatchTx() {
//        runAsyncTest(withTimeout: 300) {
//            let substrate = try await Api(rpc: self.wsClient, config: .substrate)
//            guard substrate.runtime.isBatchSupported else {
//                print("Batch is not supported in the current runtime")
//                return
//            }
//            let from = self.env.fundedKeyPairs.someElement()!
//            let toKp1 = self.env.keyPairs.someElement(without: [from])!
//            let toKp2 = self.env.keyPairs.someElement(without: [from, toKp1])!
//
//            let to1 = try toKp1.address(in: substrate)
//            let to2 = try toKp2.address(in: substrate)
//            let call1 = AnyCall(name: "transfer_allow_death",
//                                pallet: "Balances",
//                                params: ["dest": to1, "value": 15383812800])
//            let call2 = AnyCall(name: "transfer_allow_death",
//                                pallet: "Balances",
//                                params: ["dest": to2, "value": 15583812810])
//            let tx = try await substrate.tx.batchAll([call1, call2])
//            let events = try await tx.signSendAndWatch(signer: from)
//                .waitForFinalized()
//                .success()
//            XCTAssert(events.events.count > 0)
//            print("Events: \(try events.parsed())")
//        }
//    }
    #endif
}
