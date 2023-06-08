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
    func testInitializationParsing() {
        let client = JsonRpcClient(.http(url: URL(string: "https://westend-rpc.polkadot.io")!))
        
        runAsyncTest(withTimeout: 30) {
            let substrate = try await Substrate(rpc: client, config: DynamicRuntime())
            let events = try await substrate.client.events(at: nil, runtime: substrate.runtime)
            print("Events:", events as Any)
        }
    }
    
//    func testStorageCall() {
//        let disconnected = expectation(description: "Disconnected")
//        let key = SystemAccountStorageKey<PolkadotRuntime>(accountId: .default())
//        let client = HttpRpcClient(url: URL(string: "https://rpc.polkadot.io")!)
//
//        Substrate<DefaultNodeRuntime, HttpRpcClient>.create(client: client, runtime: PolkadotRuntime()) { result in
//            switch result {
//            case .failure(let err):
//                XCTFail("\(err)")
//                disconnected.fulfill()
//            case .success(let substrate):
//                let hash = try! key.iterator(registry: substrate.registry)
//                print(hash.hex)
//                disconnected.fulfill()
//            }
//        }
//
//        wait(for: [disconnected], timeout: 30.0)
//    }
    
//    func testSubstrateCreation() {
//        let client = HttpRpcClient(url: URL(string: "https://rpc.polkadot.io")!)
//
//        Substrate.create(client: client, runtime: , <#T##cb: (Result<Substrate<Runtime, RpcClient>, Error>) -> Void##(Result<Substrate<Runtime, RpcClient>, Error>) -> Void#>)
//    }
}

