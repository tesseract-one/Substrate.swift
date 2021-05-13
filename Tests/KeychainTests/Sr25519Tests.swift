//
//  Sr25519Tests.swift
//  
//
//  Created by Yehor Popovych on 06.05.2021.
//

import XCTest

#if !COCOAPODS
@testable import SubstrateKeychain
import Substrate
#else
@testable import Substrate
#endif

final class Sr25519Tests: XCTestCase {
    func testSrTestVectorShouldWork() {
        let seed = Hex.decode(hex: "9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60")!
        let pair = try? Sr25519KeyPair(seed: seed)
        let pubKey = try? Sr25519PublicKey(bytes: Hex.decode(hex: "44a996beb1eef7bdcab976ab6d2ca26104834164ecf28fb375600576fcc6eb0f")!, format: .substrate)
        XCTAssertEqual(pair?.pubKey(format: .substrate) as? Sr25519PublicKey, pubKey)
        let message = Data()
        let oSignature = pair?.sign(message: message)
        XCTAssertNotNil(oSignature)
        guard let signature = oSignature else { return }
        XCTAssertEqual(pair?.verify(message: message, signature: signature), true)
    }
    
    func testPhraseInit() {
        let phrase = "bottom drive obey lake curtain smoke basket hold race lonely fit walk"
        let pair = try? Sr25519KeyPair(phrase: phrase)
        let pubBytes = Hex.decode(hex: "46ebddef8cd9bb167dc30878d7113b7e168e6f0646beffd77d69d39bad76b47a")
        XCTAssertEqual(pair?.rawPubKey, pubBytes)
    }
    
    func testDefaultPhraseShouldBeUsed() {
        let p1 = try? Sr25519KeyPair.parse("//Alice///password")
        let p2 = try? Sr25519KeyPair.parse(DEFAULT_DEV_PHRASE + "//Alice", override: "password")
        XCTAssertEqual(p1?.rawPubKey, p2?.rawPubKey)
        
        let p3 = try? Sr25519KeyPair.parse(DEFAULT_DEV_PHRASE + "/Alice")
        let p4 = try? Sr25519KeyPair.parse("/Alice")
        XCTAssertEqual(p3?.rawPubKey, p4?.rawPubKey)
    }
    
    func testSignAndVerify() {
        let oPair = try? Sr25519KeyPair(seed: Hex.decode(hex: "fac7959dbfe72f052e5a0c3c8d6530f202b02fd8f9f5ca3580ec8deb7797479e")!)
        XCTAssertNotNil(oPair)
        guard let pair = oPair else { return }
        let message = Data("Some awesome message to sign".utf8)
        let signature = pair.sign(message: message)
        let isValid = pair.verify(message: message, signature: signature)
        XCTAssertEqual(isValid, true)
    }
    
    func testCompatibilityDeriveHardKnownPairShouldWork() {
        let pair = try? Sr25519KeyPair.parse(DEFAULT_DEV_PHRASE + "//Alice")
        // known address of DEV_PHRASE with 1.1
        let known = Hex.decode(hex: "d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d")!
        XCTAssertEqual(pair?.rawPubKey, known)
    }
    
    func testCompatibilityDeriveSoftKnownPairShouldWork() {
        let pair = try? Sr25519KeyPair.parse(DEFAULT_DEV_PHRASE + "/Alice")
        // known address of DEV_PHRASE with 1.1
        let known = Hex.decode(hex: "d6c71059dbbe9ad2b0ed3f289738b800836eb425544ce694825285b958ca755e")!
        XCTAssertEqual(pair?.rawPubKey, known)
    }
}

