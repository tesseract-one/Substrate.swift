//
//  Mnemonic.swift
//
//  See BIP39 specification for more info:
//  https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki
//
//  Created by Liu Pengpeng on 2019/10/10.
//  Forked from: https://github.com/pengpengliu/BIP39

import Foundation
import CryptoSwift

public struct Mnemonic {
    public enum Error: Swift.Error {
        case invalidMnemonic
        case invalidEntropy
    }
    
    public let phrase: [String]
    let passphrase: String
    
    public init(phrase: [String], passphrase: String = "") throws {
        if (!Mnemonic.isValid(phrase: phrase)) {
            throw Error.invalidMnemonic
        }
        self.phrase = phrase
        self.passphrase = passphrase
    }
    
    public init(entropy: [UInt8], wordlist: Wordlist = .english) throws {
        self.phrase = try Mnemonic.toMnemonic(entropy, wordlist: wordlist)
        self.passphrase = ""
    }
    
    // Entropy -> Mnemonic
    public static func toMnemonic(_ bytes: [UInt8], wordlist: Wordlist = .english) throws -> [String] {
        let entropyBits = String(bytes.flatMap { ("00000000" + String($0, radix:2)).suffix(8) })
        let checksumBits = Mnemonic.deriveChecksumBits(bytes)
        let bits = entropyBits + checksumBits
        
        var phrase = [String]()
        for i in 0..<(bits.count / 11) {
            let wi = Int(bits[bits.index(bits.startIndex, offsetBy: i * 11)..<bits.index(bits.startIndex, offsetBy: (i + 1) * 11)], radix: 2)!
            phrase.append(String(wordlist.words[wi]))
        }
        return phrase
    }
    
    // Mnemonic -> Entropy
    public static func toEntropy(_ phrase: [String], wordlist: Wordlist = .english) throws -> [UInt8] {
        let bits = phrase.map { (word) -> String in
            let index = wordlist.words.firstIndex(of: word)!
            var str = String(index, radix:2)
            while str.count < 11 {
                str = "0" + str
            }
            return str
        }.joined(separator: "")
        
        let dividerIndex = Int(Double(bits.count / 33).rounded(.down) * 32)
        let entropyBits = String(bits.prefix(dividerIndex))
        let checksumBits = String(bits.suffix(bits.count - dividerIndex))
        
        let regex = try! NSRegularExpression(pattern: "[01]{1,8}", options: .caseInsensitive)
        let entropyBytes = regex.matches(in: entropyBits, options: [], range: NSRange(location: 0, length: entropyBits.count)).map {
            UInt8(strtoul(String(entropyBits[Range($0.range, in: entropyBits)!]), nil, 2))
        }
        if (checksumBits != Mnemonic.deriveChecksumBits(entropyBytes)) {
            throw Error.invalidMnemonic
        }
        return entropyBytes
    }
    
    public static func seed(bytes: [UInt8], passphrase: String = "") throws -> [UInt8] {
        let salt = ("mnemonic" + passphrase)
        return try PKCS5.PBKDF2(
            password: bytes, salt: Array(salt.utf8),
            iterations: 2048, variant: .sha512
        ).calculate()
    }
    
    public static func isValid(phrase: [String], wordlist: Wordlist = .english) -> Bool {
        var bits = ""
        for word in phrase {
            guard let i = wordlist.words.firstIndex(of: word) else { return false }
            bits += ("00000000000" + String(i, radix: 2)).suffix(11)
        }
        
        let dividerIndex = bits.count / 33 * 32
        let entropyBits = String(bits.prefix(dividerIndex))
        let checksumBits = String(bits.suffix(bits.count - dividerIndex))
        
        let regex = try! NSRegularExpression(pattern: "[01]{1,8}", options: .caseInsensitive)
        let entropyBytes = regex.matches(in: entropyBits, options: [], range: NSRange(location: 0, length: entropyBits.count)).map {
            UInt8(strtoul(String(entropyBits[Range($0.range, in: entropyBits)!]), nil, 2))
        }
        return checksumBits == deriveChecksumBits(entropyBytes)
    }
    
    public static func deriveChecksumBits(_ bytes: [UInt8]) -> String {
        let ENT = bytes.count * 8;
        let CS = ENT / 32
        
        let hash = bytes.sha256()
        let hashbits = String(hash.flatMap { ("00000000" + String($0, radix:2)).suffix(8) })
        return String(hashbits.prefix(CS))
    }
    
    public func seed() throws -> [UInt8] {
        let mnemonic = self.phrase.joined(separator: " ")
        return try Self.seed(bytes: Array(mnemonic.utf8), passphrase: passphrase)
    }
}

extension Mnemonic: Equatable {
    public static func == (lhs: Mnemonic, rhs: Mnemonic) -> Bool {
        return lhs.phrase == rhs.phrase && lhs.passphrase == rhs.passphrase
    }
}
