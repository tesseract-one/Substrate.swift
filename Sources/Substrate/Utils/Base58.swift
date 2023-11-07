//
//  Base58.swift
//  
//
//  Created by Yehor Popovych on 04.05.2021.
//
//  Based on https://github.com/Alja7dali/swift-base58 project.
//

import Foundation

public enum Base58 {
    public enum DecodingError: Error {
        case invalidByte(UInt8)
    }
    
    public struct Alphabet {
        public let alphabet: [UInt8]
        public let table: [Int8]
        
        public init(_ alphabet: [UInt8]) {
            precondition(alphabet.count == 58, "Alphabet should be 58 elements long")
            self.alphabet = alphabet
            var table = Array<Int8>(repeating: -1, count: Int(UInt8.max))
            for (index, char) in alphabet.enumerated() {
                table[Int(char)] = Int8(index)
            }
            self.table = table
        }
        
        public init(_ alphabet: String) {
            self.init(Array(alphabet.utf8))
        }
        
        @inlinable public var zero: UInt8 { alphabet[0] }
    }
    
    public static func encode(_ data: Data, alphabet: Alphabet = Self._alphabet) -> String {
        data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            var zerosCount: Int = 0
            while bytes[zerosCount] == 0 { zerosCount += 1 }

            let b58Count = (((bytes.count - zerosCount) * 138) / 100) + 1
            
            var b58 = Data(repeating: 0, count: b58Count)
            return b58.withUnsafeMutableBytes { (b58: UnsafeMutableRawBufferPointer) in
                var x = zerosCount
                var count = 0

                while x < bytes.count {
                    var carry = Int(bytes[x]), i = 0, j = b58Count - 1
                    while j > -1 {
                        if carry != 0 || i < count {
                            carry += 256 * Int(b58[j])
                            b58[j] = UInt8(carry % 58)
                            carry /= 58
                            i += 1
                        }
                        j -= 1
                    }
                    count = i
                    x += 1
                }

                // skip leading zeros
                var leadingZeros = 0
                while b58[leadingZeros] == 0 { leadingZeros += 1 }

                return alphabet.alphabet.withUnsafeBufferPointer { alphabet in
                    var result = Data()
                    result.reserveCapacity(zerosCount + b58Count - leadingZeros)
                    result.append(Data(repeating: alphabet[0], count: zerosCount))
                    b58[leadingZeros...].forEach { result.append(alphabet[Int($0)]) }
                    return String(data: result, encoding: .utf8)!
                }
            }
        }
    }
    
    public static func decode(_ string: String, alphabet: Alphabet = Self._alphabet) throws -> Data {
        try Array(string.utf8).withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            var zerosCount = 0
            while bytes[zerosCount] == alphabet.zero { zerosCount += 1 }
                
            let b58Count = (((bytes.count - zerosCount) * 733) / 1000) + 1
            
            var b58 = Data(repeating: 0, count: b58Count)
            let leadingZeros = try b58.withUnsafeMutableBytes { (b58: UnsafeMutableRawBufferPointer) in
                try alphabet.table.withUnsafeBufferPointer { table in
                    var x = zerosCount
                    var count = 0
                    
                    while x < bytes.count {
                        let b58Index = table[Int(bytes[x])]
                        guard b58Index >= 0 else { throw DecodingError.invalidByte(bytes[x]) }
                        
                        var carry = Int(b58Index), i = 0, j = b58Count - 1
                        while j > -1 {
                            if carry != 0 || i < count {
                                carry += 58 * Int(b58[j])
                                b58[j] = UInt8(carry % 256)
                                carry /= 256
                                i += 1
                            }
                            j -= 1
                        }
                        count = i
                        x += 1
                    }
                    
                    // skip leading zeros
                    var leadingZeros = 0
                    while b58[leadingZeros] == 0 { leadingZeros += 1 }
                    return leadingZeros
                }
            }
            
            var result = Data()
            result.reserveCapacity(zerosCount + b58Count - leadingZeros)
            result.append(Data(repeating: 0, count: zerosCount))
            result.append(b58[leadingZeros...])
            return result
        }
    }
    
    public static let _alphabet = Alphabet("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")
}
