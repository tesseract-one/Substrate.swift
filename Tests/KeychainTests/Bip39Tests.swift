//
//  Bip39Tests.swift
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

final class Bip39Tests: XCTestCase {
    func testMnemonicToSeedPassword() {
        let phrase = "exhaust toast cinnamon peasant unusual canvas sudden coconut under asthma surge control high glimpse spirit"
        let seed = "0x749abc5152dc457760ce0f3f69ecfc80c86e5180ae7a1f2f7d59e13b51759aa178abce7fbf651666fb1c1a6b2b4fbed39c6eb6fbedf0c19bbbf1c1d94e7a8272"
        let mnemonic = try? Mnemonic(phrase: phrase.components(separatedBy: " "), passphrase: "testpassword")
        let mSeed = (try? mnemonic.flatMap { Data(try $0.seed()) }) ?? Data()
        XCTAssertEqual(Hex.encode(data: mSeed), seed)
    }
    
    func testMnemonicToSeed() {
        let phrase = "future bless domain banana fame record dolphin jeans gift liquid spike olympic tube subject stage"
        let seed = "0x466984d7fe79c18d396e01543f11323c8c5275f2ce830756be2eb0a5b74fab8c9cf666cf0ed9b42a32cc2400539a51138f81ceb59a0d06ea25ad20ad477e6591"
        let mnemonic = try? Mnemonic(phrase: phrase.components(separatedBy: " "))
        let mSeed = (try? mnemonic.flatMap { Data(try $0.seed()) }) ?? Data()
        XCTAssertEqual(Hex.encode(data: mSeed), seed)
    }
    
    func testEntropyToMnemonic() {
        let phrase = "twelve album fashion trip tell wood initial cactus edit swarm endorse bunker core girl town"
        let entHex = "0xeb00bd4d746dedfa5cf900467b6d270f3304c4b9"
        let entropy = Hex.decode(hex: entHex)!
        let mnemonic = try? Mnemonic(entropy: Array(entropy), wordlist: .english)
        XCTAssertEqual(mnemonic?.phrase, phrase.components(separatedBy: " "))
    }
}

