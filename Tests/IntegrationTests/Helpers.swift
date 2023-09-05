//
//  Helpers.swift
//  
//
//  Created by Yehor Popovych on 05.01.2023.
//

import XCTest
import Substrate
import SubstrateKeychain

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
    public let wsUrlString: String
    public let httpUrlString: String
    
    init() {
        self.mnemonic = ProcessInfo.processInfo.environment["TEST_MNEMONIC"] ?? DEFAULT_DEV_PHRASE
        self.httpUrlString = ProcessInfo.processInfo.environment["NODE_HTTP_URL"] ?? "http://127.0.0.1:9944"
        self.wsUrlString = ProcessInfo.processInfo.environment["NODE_WS_URL"] ?? "ws://127.0.0.1:9944"
    }
    
    var httpUrl: URL { URL(string: httpUrlString)! }
    var wsUrl: URL { URL(string: wsUrlString)! }
    
    public var sudoKeyPair: Sr25519KeyPair { mutating get { kpAlice } }
    public var fundedKeyPairs: [Sr25519KeyPair] { mutating get  { [kpAlice, kpBob] } }
    public var keyPairs: [Sr25519KeyPair] { mutating get {
        [kpAlice, kpBob, kpCharlie, kpDave, kpEve, kpFerdie]
    } }
    
    lazy var kpAlice: Sr25519KeyPair = try! Sr25519KeyPair(parsing: mnemonic + "//Alice")
    lazy var kpBob: Sr25519KeyPair = try! Sr25519KeyPair(parsing: mnemonic + "//Bob")
    lazy var kpCharlie: Sr25519KeyPair = try! Sr25519KeyPair(parsing: mnemonic + "//Charlie")
    lazy var kpDave: Sr25519KeyPair = try! Sr25519KeyPair(parsing: mnemonic + "//Dave")
    lazy var kpEve: Sr25519KeyPair = try! Sr25519KeyPair(parsing: mnemonic + "//Eve")
    lazy var kpFerdie: Sr25519KeyPair = try! Sr25519KeyPair(parsing: mnemonic + "//Ferdie")
}

extension Array where Element: Hashable {
    public func someElement(without exc: [Element] = []) -> Element? {
        if exc.count > 0 {
            return Set(self).subtracting(exc).randomElement()
        } else {
            return self.randomElement()
        }
    }
}
