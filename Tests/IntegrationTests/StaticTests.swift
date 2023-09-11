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
    public typealias Config = Configs.Substrate
    
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
    
    func config() -> Configs.Registry<Config> {
        return try! .substrate(
            frames: [Config.System(), Config.Balances(), Config.TransactionPayment()],
            runtimeApis: [Config.TransactionPaymentApi()]
        )
    }
    
    func testInitialization() {
        runAsyncTest(withTimeout: 30) {
            let _ = try await Api(rpc: self.httpClient, config: self.config())
        }
    }
    
    func testStorageValueCall() {
        runAsyncTest(withTimeout: 30) {
            let substrate = try await Api(rpc: self.httpClient, config: self.config())
            let entry = try substrate.query.entry(Config.System.Storage.Account.self)
            let alice = try self.env.kpAlice.pubKey.account(in: substrate)
            let value = try await entry.value(alice)
            XCTAssertNotNil(value)
        }
    }
    
    func testStorageIteration() {
        runAsyncTest(withTimeout: 30) {
            let substrate = try await Api(rpc: self.httpClient, config: self.config())
            let entry = try substrate.query.entry(Config.System.Storage.Account.self)
            var found = false
            for try await _ in entry.entries().prefix(2) {
                found = true
            }
            XCTAssert(found)
        }
    }
    
    func testBlock() {
        runAsyncTest(withTimeout: 30) {
            let substrate = try await Api(rpc: self.httpClient, config: self.config())
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
            let substrate = try await Api(rpc: self.httpClient, config: self.config())
            let to = try toKp.address(in: substrate)
            let call = Config.Balances.Call.TransferAllowDeath(dest: to,
                                                               value: 15483812856)
            let tx = try await substrate.tx.new(call)
            let _ = try await tx.signAndSend(signer: from)
        }
    }
    
    func testTransferBatchTx() {
        runAsyncTest(withTimeout: 30) {
            let substrate = try await Api(rpc: self.httpClient, config: self.config())
            guard substrate.runtime.isBatchSupported else {
                print("Batch is not supported in the current runtime")
                return
            }
            let from = self.env.fundedKeyPairs.someElement()!
            let toKp1 = self.env.keyPairs.someElement(without: [from])!
            let toKp2 = self.env.keyPairs.someElement(without: [from, toKp1])!

            let to1 = try toKp1.address(in: substrate)
            let to2 = try toKp2.address(in: substrate)
            let call1 = Config.Balances.Call.TransferAllowDeath(dest: to1,
                                                                value: 15383812800)
            let call2 = Config.Balances.Call.TransferAllowDeath(dest: to2,
                                                                value: 15583812810)
            let tx = try await substrate.tx.batchAll([call1, call2])
            let _ = try await tx.signAndSend(signer: from)
        }
    }
    
    func testQueryPaymentInfo() {
        runAsyncTest(withTimeout: 30) {
            let from = self.env.fundedKeyPairs.someElement()!
            let toKp = self.env.keyPairs.someElement(without: [from])!
            let substrate = try await Api(rpc: self.httpClient, config: self.config())
            let to = try toKp.address(in: substrate)
            let call = Config.Balances.Call.TransferAllowDeath(dest: to,
                                                               value: 15483812856)
            let tx = try await substrate.tx.new(call).fakeSign(account: from.pubKey)
            let queryInfo = try Config.TransactionPaymentApi.QueryInfo(
                extrinsic: tx.extrinsic,
                runtime: substrate.runtime
            )
            let _ = try await substrate.call.execute(call: queryInfo)
        }
    }
    
    func testQueryFeeDetails() {
        runAsyncTest(withTimeout: 30) {
            let from = self.env.fundedKeyPairs.someElement()!
            let toKp = self.env.keyPairs.someElement(without: [from])!
            let substrate = try await Api(rpc: self.httpClient, config: self.config())
            let to = try toKp.address(in: substrate)
            let call = Config.Balances.Call.TransferAllowDeath(dest: to,
                                                               value: 15483812856)
            let tx = try await substrate.tx.new(call)
            let _ = try await tx.feeDetails(account: from.pubKey)
        }
    }
    
    #if !os(Linux) && !os(Windows)
    func testTransferAndWatchTx() {
        runAsyncTest(withTimeout: 300) {
            let from = self.env.fundedKeyPairs.someElement()!
            let toKp = self.env.keyPairs.someElement(without: [from])!
            let substrate = try await Api(rpc: self.wsClient, config: self.config())
            let to = try toKp.address(in: substrate)
            let call = Config.Balances.Call.TransferAllowDeath(dest: to,
                                                               value: 15483812856)
            let tx = try await substrate.tx.new(call)
            let events = try await tx.signSendAndWatch(signer: from)
                .waitForInBlock()
                .success()
            XCTAssert(events.events.count > 0)
            let withdraw = try events.first(event: Config.Balances.Event.Withdraw.self)
            XCTAssertNotNil(withdraw)
            print(withdraw!)
            let transfer = try events.first(event: Config.Balances.Event.Transfer.self)
            XCTAssertNotNil(transfer)
            print(transfer!)
            let feePaid = try events.first(event: Config.TransactionPayment.Event.TransactionFeePaid.self)
            XCTAssertNotNil(feePaid)
            print(feePaid!)
            let success = try events.first(event: Config.System.Event.ExtrinsicSuccess.self)
            XCTAssertNotNil(success)
            print(success!)
        }
    }
    
    func testTransferAndWatchBatchTx() {
        runAsyncTest(withTimeout: 300) {
            let substrate = try await Api(rpc: self.wsClient, config: self.config())
            guard substrate.runtime.isBatchSupported else {
                print("Batch is not supported in the current runtime")
                return
            }
            let from = self.env.fundedKeyPairs.someElement()!
            let toKp1 = self.env.keyPairs.someElement(without: [from])!
            let toKp2 = self.env.keyPairs.someElement(without: [from, toKp1])!

            let to1 = try toKp1.address(in: substrate)
            let to2 = try toKp2.address(in: substrate)
            let call1 = Config.Balances.Call.TransferAllowDeath(dest: to1,
                                                                value: 15383812800)
            let call2 = Config.Balances.Call.TransferAllowDeath(dest: to2,
                                                                value: 15583812810)
            let tx = try await substrate.tx.batchAll([call1, call2])
            let events = try await tx.signSendAndWatch(signer: from)
                .waitForInBlock()
                .success()
            XCTAssert(events.events.count > 0)
            print("Events: \(try events.parsed())")
        }
    }
    #endif
}
