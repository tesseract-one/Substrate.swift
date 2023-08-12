//
//  Helpers.swift
//  
//
//  Created by Yehor Popovych on 05.01.2023.
//

import XCTest
import Substrate
#if !COCOAPODS
import SubstrateKeychain
#endif

extension XCTestCase {
    func runAsyncTest(
        named testName: String = #function,
        in file: StaticString = #file,
        at line: UInt = #line,
        withTimeout timeout: TimeInterval = 10,
        test: @escaping () async throws -> Void
    ) {
        var thrownError: Error?
        let errorHandler = { thrownError = $0 }
        let expectation = expectation(description: testName)

        Task {
            do {
                try await test()
            } catch {
                errorHandler(error)
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: timeout)

        if let error = thrownError {
            XCTFail(
                "Async error thrown: \(error)",
                file: file,
                line: line
            )
        }
    }
}


struct Environment {
    private let mnemonic: String
    public let host: String
    public let wsPort: String
    public let httpPort: String
    
    init() {
        self.mnemonic = ProcessInfo.processInfo.environment["TEST_MNEMONIC"] ?? DEFAULT_DEV_PHRASE
        self.host = ProcessInfo.processInfo.environment["NODE_HOST"] ?? "127.0.0.1"
        self.httpPort = ProcessInfo.processInfo.environment["NODE_HTTP_PORT"] ?? "9933"
        self.wsPort = ProcessInfo.processInfo.environment["NODE_WS_PORT"] ?? "9944"
    }
    
    var httpUrl: URL { URL(string: "http://\(host):\(httpPort)")! }
    var wsUrl: URL { URL(string: "ws://\(host):\(wsPort)")! }
    
    lazy var kpAlice: Sr25519KeyPair = try! Sr25519KeyPair(parsing: mnemonic + "//Alice")
    lazy var kpBob: Sr25519KeyPair = try! Sr25519KeyPair(parsing: mnemonic + "//Bob")
    lazy var kpJohn: Sr25519KeyPair = try! Sr25519KeyPair(parsing: mnemonic + "//John")
    lazy var kpJane: Sr25519KeyPair = try! Sr25519KeyPair(parsing: mnemonic + "//Jane")
    
    public var keyPairs: [Sr25519KeyPair] { mutating get { [kpAlice, kpBob, kpJohn, kpJane] } }
    
    public mutating func randomKeyPair(exclude kps: [Sr25519KeyPair] = []) -> Sr25519KeyPair {
        if kps.count > 0 {
            return Set(keyPairs).subtracting(kps).randomElement()!
        } else {
            return keyPairs.randomElement()!
        }
    }
}
