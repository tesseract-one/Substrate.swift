//
//  File.swift
//  
//
//  Created by Yehor Popovych on 12/25/20.
//

import XCTest
import ScaleCodec
@testable import Substrate

final class SubstrateTests: XCTestCase {
    func testMetadataParsing() {
        let disconnected = expectation(description: "Disconnected")
        let client = HttpRpcClient(url: URL(string: "https://rpc.polkadot.io")!)
        
        let parse = { (data: Data) in
            let rmetadata: RuntimeVersionedMetadata = try! SCALE.default.decode(from: data)
            let _ = try! Metadata(runtime: rmetadata.metadata)
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .substrate_iso8601millis
            encoder.dataEncodingStrategy = .substrate_prefixedHex
            let json = try! encoder.encode(rmetadata.metadata as! RuntimeMetadataV12)
            print("Metadata", String(data: json, encoding: .utf8)!)
        }
        
        client.call(method: "state_getMetadata", params: Array<Int>()) { (res: Result<Data, RpcClientError>) in
            switch res {
            case .success(let data): parse(data)
            case .failure(let err): print("Erorr", err)
            }
            disconnected.fulfill()
        }
        
        wait(for: [disconnected], timeout: 30.0)
    }
    
    func testStorageCall() {
        let disconnected = expectation(description: "Disconnected")
        let key = SystemAccountStorageKey<PolkadotRuntime>(accountId: .default())
        let client = HttpRpcClient(url: URL(string: "https://rpc.polkadot.io")!)
        
        Substrate<DefaultNodeRuntime, HttpRpcClient>.create(client: client, runtime: PolkadotRuntime()) { result in
            switch result {
            case .failure(let err):
                XCTFail("\(err)")
                disconnected.fulfill()
            case .success(let substrate):
                let hash = try! substrate.registry.hash(iteratorOf: key)
                print(hash.hex)
                disconnected.fulfill()
            }
        }
        
        wait(for: [disconnected], timeout: 30.0)
    }
    
//    func testSubstrateCreation() {
//        let client = HttpRpcClient(url: URL(string: "https://rpc.polkadot.io")!)
//
//        Substrate.create(client: client, runtime: , <#T##cb: (Result<Substrate<Runtime, RpcClient>, Error>) -> Void##(Result<Substrate<Runtime, RpcClient>, Error>) -> Void#>)
//    }
}

