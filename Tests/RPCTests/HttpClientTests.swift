//
//  HttpClientTests.swift
//  
//
//  Created by Yehor Popovych on 12/15/20.
//
import XCTest
import Serializable

#if !COCOAPODS
import SubstrateRpc
#else
import Substrate
#endif

final class HttpClientTests: XCTestCase {
    struct BlockHash: Decodable {
        let hash: Data
        
        init(from decoder: Decoder) throws {
            let string = try decoder.singleValueContainer().decode(String.self)
            let dataDecoder = SerializableValue.DataDecodingStrategy.hex
            hash = try dataDecoder.decode(string)
        }
    }
    
    func testSimpleRequest() {
        let expect = expectation(description: "Simple Request")
        let client = HttpRpcClient(url: URL(string: "https://rpc.polkadot.io")!)
        
        client.call(method: "chain_getBlock", params: Array<Int>()) { (result: Result<SerializableValue, RpcClientError>) in
            print("Result: \(result)")
            expect.fulfill()
        }
        
        wait(for: [expect], timeout: 10)
    }
    
    func testCustomType() {
        let expect = expectation(description: "Custom Type Request")
        let client = HttpRpcClient(url: URL(string: "https://rpc.polkadot.io")!)
        
        client.call(method: "chain_getBlockHash", params: [1]) { (result: Result<BlockHash, RpcClientError>) in
            print("Block 1 hash: \(result)")
            expect.fulfill()
        }
        
        wait(for: [expect], timeout: 10)
    }
}
