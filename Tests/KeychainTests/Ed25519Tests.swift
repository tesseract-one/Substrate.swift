//
//  Ed25519Tests.swift
//  
//
//  Created by Yehor Popovych on 14.05.2021.
//

import XCTest
import Bip39
import Substrate
@testable import SubstrateKeychain

final class Ed25519Tests: XCTestCase {
    func testDefaultPhraseShouldBeUsed() {
        let p1 = try? Ed25519KeyPair(parsing: "//Alice///password")
        let p2 = try? Ed25519KeyPair(parsing: DEFAULT_DEV_PHRASE + "//Alice", override: "password")
        XCTAssertNotNil(p1)
        XCTAssertEqual(p1?.raw, p2?.raw)
    }
    
    func testSeedAndDeriveShouldWork() {
        let seed = Data(hex: "9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60")!
        let oPair = try? Ed25519KeyPair(seed: seed)
        XCTAssertNotNil(oPair)
        guard let pair = oPair else { return }
        let derived = try? pair.derive(path: [.hard(Data(repeating: 0, count: 32))])
        let seed2 = Data(hex: "ede3354e133f9c8e337ddd6ee5415ed4b4ffe5fc7d21e933f4930a3730e5b21c")!
        let pair2 = try? Ed25519KeyPair(seed: seed2)
        XCTAssertNotNil(pair2)
        XCTAssertEqual(derived?.pubKey.raw, pair2?.pubKey.raw)
    }
    
    func testTestVectorShouldWork() {
        let seed = Data(hex: "9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60")!
        let oPair = try? Ed25519KeyPair(seed: seed)
        XCTAssertNotNil(oPair)
        guard let pair = oPair else { return }
        let expPublic = Data(hex: "d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a")!
        XCTAssertEqual(pair.pubKey.raw, expPublic)
        let message = Data()
        let signature = Data(hex: "e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e065224901555fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b")!
        XCTAssertEqual(pair.sign(message: message).raw, signature)
        XCTAssertTrue(pair.verify(message: message, signature: try! Ed25519Signature(raw: signature)))
    }
    
    func testTestVectorByStringShouldWork() {
        let oPair = try? Ed25519KeyPair(parsing: "0x9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60")
        XCTAssertNotNil(oPair)
        guard let pair = oPair else { return }
        let expPublic = Data(hex: "d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a")!
        XCTAssertEqual(pair.pubKey.raw, expPublic)
        let message = Data()
        let signature = Data(hex: "e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e065224901555fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b")!
        XCTAssertEqual(pair.sign(message: message).raw, signature)
        XCTAssertTrue(pair.verify(message: message, signature: try! Ed25519Signature(raw: signature)))
    }
    
    func testGeneratedPairShouldWork() {
        let pair = Ed25519KeyPair()
        let message = Data("Something important".utf8)
        let signature = pair.sign(message: message)
        XCTAssertTrue(pair.verify(message: message, signature: signature))
        XCTAssertFalse(pair.verify(message: Data("Something else".utf8), signature: signature))
    }
    
    func testSeededPairShouldWork() {
        let oPair = try? Ed25519KeyPair(seed: Data("12345678901234567890123456789012".utf8))
        XCTAssertNotNil(oPair)
        guard let pair = oPair else { return }
        let expPublic = Data(hex: "2f8c6129d816cf51c374bc7f08c3e63ed156cf78aefb4a6550d97b87997977ee")!
        XCTAssertEqual(pair.pubKey.raw, expPublic)
        let message = Data(hex: "2f8c6129d816cf51c374bc7f08c3e63ed156cf78aefb4a6550d97b87997977ee00000000000000000200d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a4500000000000000")!
        let signature = pair.sign(message: message)
        XCTAssertTrue(pair.verify(message: message, signature: signature))
        XCTAssertFalse(pair.verify(message: Data("Other message".utf8), signature: signature))
    }
    
    func testGenerateFromPhraseRecoveryPossible() {
        let mnemonic = try! Mnemonic(strength: 128)
        let oPair = try? Ed25519KeyPair(phrase: mnemonic.mnemonic(wordlist: .english).joined(separator: " "))
        XCTAssertNotNil(oPair)
        guard let pair = oPair else { return }
        let pair2 = try? Ed25519KeyPair(phrase: mnemonic.mnemonic(wordlist: .english).joined(separator: " "))
        XCTAssertEqual(pair.raw, pair2?.raw)
    }
    
    func testGenerateWithPasswordPhraseRecoveryPossible() {
        let mnemonic = try! Mnemonic(strength: 128)
        let oPair = try? Ed25519KeyPair(
            phrase: mnemonic.mnemonic(wordlist: .english).joined(separator: " "),
            password: "password"
        )
        XCTAssertNotNil(oPair)
        guard let pair = oPair else { return }
        let pair2 = try? Ed25519KeyPair(
            phrase: mnemonic.mnemonic(wordlist: .english).joined(separator: " "),
            password: "password"
        )
        XCTAssertEqual(pair.raw, pair2?.raw)
    }
    
    func testPasswordDoesSomething() {
        let mnemonic = try! Mnemonic(strength: 128)
        let oPair = try? Ed25519KeyPair(
            phrase: mnemonic.mnemonic(wordlist: .english).joined(separator: " "),
            password: "password"
        )
        XCTAssertNotNil(oPair)
        guard let pair = oPair else { return }
        let pair2 = try? Ed25519KeyPair(
            phrase: mnemonic.mnemonic(wordlist: .english).joined(separator: " ")
        )
        XCTAssertNotEqual(pair.pubKey.raw, pair2?.pubKey.raw)
    }
    
    func testSs58CheckRoundtripWorks() {
        let oPair = try? Ed25519KeyPair(seed: Data("12345678901234567890123456789012".utf8))
        XCTAssertNotNil(oPair)
        guard let pair = oPair else { return }
        let ss58 = try! pair.pubKey.ss58(format: .substrate)
        let pub = try? Ed25519PublicKey.from(ss58: ss58)
        XCTAssertEqual(pair.pubKey.raw, pub?.0.raw)
        XCTAssertEqual(pub?.1, .substrate)
    }
}
