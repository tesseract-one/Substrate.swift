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
    
    public static func encode(
        _ bytes: [UInt8],
        encoder mapper: (UInt8) -> UInt8 = Self._encodeByte,
        zeroSymbol: UInt8 = Self._alphabet[0]
    ) -> String {
        var zerosCount = 0
        while bytes[zerosCount] == 0 {
            zerosCount += 1
        }
        
        let bytesCount = bytes.count - zerosCount
        let b58Count = ((bytesCount * 138) / 100) + 1
        var b58 = [UInt8](repeating: 0, count: b58Count)
        var count = 0
        
        var x = zerosCount
        while x < bytesCount {
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
        while b58[leadingZeros] == 0 {
            leadingZeros += 1
        }
        
        let result = Data(repeating: zeroSymbol, count: zerosCount) + Data(b58[leadingZeros...]).map(mapper)
        return String(data: result, encoding: .ascii)!
    }
    
    public static func decode(
        _ string: String,
        decoder mapper: (UInt8) -> UInt8? = Self._decodeByte,
        zeroSymbol: UInt8 = Self._alphabet[0]
    ) throws -> Array<UInt8> {
        let bytes = Array(string.utf8)
        
        var onesCount = 0
        
        while bytes[onesCount] == zeroSymbol {
            onesCount += 1
        }
        
        let bytesCount = bytes.count - onesCount
        let b58Count = ((bytesCount * 733) / 1000) + 1 - onesCount
        var b58 = [UInt8](repeating: 0, count: b58Count)
        var count = 0
        
        var x = onesCount
        while x < bytesCount {
            guard let b58Index = mapper(bytes[x]) else {
                throw DecodingError.invalidByte(bytes[x])
            }
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
        while b58[leadingZeros] == 0 {
            leadingZeros += 1
        }
        
        return [UInt8](repeating: 0, count: onesCount) + [UInt8](b58[leadingZeros...])
    }
    
    public static let _alphabet = [UInt8]("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz".utf8)
    
    public static let _decodingTable: [UInt8: UInt8] = {
        let pairs = Self._alphabet.enumerated().map { index, char in
            (char, UInt8(index))
        }
        return Dictionary(pairs) { (l, _) in l }
    }()
    
    public static func _encodeByte(byte: UInt8) -> UInt8 {
        byte < Self._alphabet.count ? Self._alphabet[Int(byte)] : .max
    }
    
    public static func _decodeByte(char: UInt8) -> UInt8? {
        Self._decodingTable[char]
    }
}
