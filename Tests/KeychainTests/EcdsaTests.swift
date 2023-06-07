//
//  Ed25519Tests.swift
//  
//
//  Created by Yehor Popovych on 14.05.2021.
//

import XCTest
import Bip39
#if !COCOAPODS
@testable import SubstrateKeychain
import Substrate
#else
@testable import Substrate
#endif

final class EcdsaTests: XCTestCase {
    func testDefaultPhraseShouldBeUsed() {
        let p1 = try? EcdsaKeyPair(parsing: "//Alice///password")
        let p2 = try? EcdsaKeyPair(parsing: DEFAULT_DEV_PHRASE + "//Alice", override: "password")
        XCTAssertNotNil(p1)
        XCTAssertEqual(p1?.raw, p2?.raw)
    }
    
    func testSeedAndDeriveShouldWork() {
        let seed = Data(hex: "9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60")!
        let oPair = try? EcdsaKeyPair(seed: seed)
        XCTAssertNotNil(oPair)
        guard let pair = oPair else { return }
        let derived = try? pair.derive(path: [.hard(Data(repeating: 0, count: 32))])
        let seed2 = Data(hex: "b8eefc4937200a8382d00050e050ced2d4ab72cc2ef1b061477afb51564fdd61")!
        let pair2 = try? EcdsaKeyPair(seed: seed2)
        XCTAssertNotNil(pair2)
        XCTAssertEqual(derived?.pubKey.raw, pair2?.pubKey.raw)
    }
    
    func testTestVectorShouldWork() {
        let seed = Data(hex: "9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60")!
        let oPair = try? EcdsaKeyPair(seed: seed)
        XCTAssertNotNil(oPair)
        guard let pair = oPair else { return }
        let expPublic = Data(hex: "028db55b05db86c0b1786ca49f095d76344c9e6056b2f02701a7e7f3c20aabfd91")!
        XCTAssertEqual(pair.pubKey.raw, expPublic)
        let message = Data()
        let signature = Data(hex: "3dde91174bd9359027be59a428b8146513df80a2a3c7eda2194f64de04a69ab97b753169e94db6ffd50921a2668a48b94ca11e3d32c1ff19cfe88890aa7e8f3c00")!
        XCTAssertEqual(pair.sign(message: message).raw, signature)
        XCTAssertTrue(pair.verify(message: message, signature: try! EcdsaSignature(raw: signature)))
    }

    func testTestVectorByStringShouldWork() {
        let oPair = try? EcdsaKeyPair(parsing: "0x9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60")
        XCTAssertNotNil(oPair)
        guard let pair = oPair else { return }
        let expPublic = Data(hex: "028db55b05db86c0b1786ca49f095d76344c9e6056b2f02701a7e7f3c20aabfd91")!
        XCTAssertEqual(pair.pubKey.raw, expPublic)
        let message = Data()
        let signature = Data(hex: "3dde91174bd9359027be59a428b8146513df80a2a3c7eda2194f64de04a69ab97b753169e94db6ffd50921a2668a48b94ca11e3d32c1ff19cfe88890aa7e8f3c00")!
        XCTAssertEqual(pair.sign(message: message).raw, signature)
        XCTAssertTrue(pair.verify(message: message, signature: try! EcdsaSignature(raw: signature)))
    }

    func testGeneratedPairShouldWork() {
        let pair = EcdsaKeyPair()
        let message = Data("Something important".utf8)
        let signature = pair.sign(message: message)
        XCTAssertTrue(pair.verify(message: message, signature: signature))
        XCTAssertFalse(pair.verify(message: Data("Something else".utf8), signature: signature))
    }

    func testSeededPairShouldWork() {
        let oPair = try? EcdsaKeyPair(seed: Data("12345678901234567890123456789012".utf8))
        XCTAssertNotNil(oPair)
        guard let pair = oPair else { return }
        let expPublic = Data(hex: "035676109c54b9a16d271abeb4954316a40a32bcce023ac14c8e26e958aa68fba9")!
        XCTAssertEqual(pair.pubKey.raw, expPublic)
        let message = Data(hex: "2f8c6129d816cf51c374bc7f08c3e63ed156cf78aefb4a6550d97b87997977ee00000000000000000200d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a4500000000000000")!
        let signature = pair.sign(message: message)
        XCTAssertTrue(pair.verify(message: message, signature: signature))
        XCTAssertFalse(pair.verify(message: Data("Other message".utf8), signature: signature))
    }

    func testGenerateFromPhraseRecoveryPossible() {
        let mnemonic = try! Mnemonic(strength: 128)
        let oPair = try? EcdsaKeyPair(phrase: mnemonic.mnemonic(wordlist: .english).joined(separator: " "))
        XCTAssertNotNil(oPair)
        guard let pair = oPair else { return }
        let pair2 = try? EcdsaKeyPair(phrase: mnemonic.mnemonic(wordlist: .english).joined(separator: " "))
        XCTAssertEqual(pair.raw, pair2?.raw)
    }

    func testGenerateWithPasswordPhraseRecoveryPossible() {
        let mnemonic = try! Mnemonic(strength: 128)
        let oPair = try? EcdsaKeyPair(
            phrase: mnemonic.mnemonic(wordlist: .english).joined(separator: " "),
            password: "password"
        )
        XCTAssertNotNil(oPair)
        guard let pair = oPair else { return }
        let pair2 = try? EcdsaKeyPair(
            phrase: mnemonic.mnemonic(wordlist: .english).joined(separator: " "),
            password: "password"
        )
        XCTAssertEqual(pair.raw, pair2?.raw)
    }

    func testPasswordDoesSomething() {
        let mnemonic = try! Mnemonic(strength: 128)
        let oPair = try? EcdsaKeyPair(
            phrase: mnemonic.mnemonic(wordlist: .english).joined(separator: " "),
            password: "password"
        )
        XCTAssertNotNil(oPair)
        guard let pair = oPair else { return }
        let pair2 = try? EcdsaKeyPair(
            phrase: mnemonic.mnemonic(wordlist: .english).joined(separator: " ")
        )
        XCTAssertNotEqual(pair.raw, pair2?.raw)
    }

    func testSs58CheckRoundtripWorks() {
        let oPair = try? EcdsaKeyPair(seed: Data("12345678901234567890123456789012".utf8))
        XCTAssertNotNil(oPair)
        guard let pair = oPair else { return }
        let ss58 = pair.pubKey.ss58(format: .substrate)
        let pub = try? EcdsaPublicKey.from(ss58: ss58)
        XCTAssertEqual(pair.pubKey.raw, pub?.0.raw)
        XCTAssertEqual(pub?.1, .substrate)
    }
}
