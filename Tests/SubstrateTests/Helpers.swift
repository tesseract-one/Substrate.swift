//
//  Helpers.swift
//  
//
//  Created by Yehor Popovych on 05.01.2023.
//

import XCTest
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
    
    init() {
        self.mnemonic = ProcessInfo.processInfo.environment["TEST_MNEMONIC"]!
    }
    
    lazy var kpAlice: Sr25519KeyPair = try! Sr25519KeyPair(parsing: mnemonic + "//Alice")
    lazy var kpBob: Sr25519KeyPair = try! Sr25519KeyPair(parsing: mnemonic + "//Bob")
    lazy var kbJohn: Sr25519KeyPair = try! Sr25519KeyPair(parsing: mnemonic + "//John")
    lazy var kbJane: Sr25519KeyPair = try! Sr25519KeyPair(parsing: mnemonic + "//Jane")
    
    public var keyPairs: [Sr25519KeyPair] { mutating get { [kpAlice, kpBob, kbJohn, kbJane] } }
    
    public mutating func randomKeyPair(exclude kp: Sr25519KeyPair? = nil) -> Sr25519KeyPair {
        if let excl = kp {
            return keyPairs.filter { $0 != excl }.randomElement()!
        } else {
            return keyPairs.randomElement()!
        }
    }
}
