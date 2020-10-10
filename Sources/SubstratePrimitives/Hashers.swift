//
//  Hashers.swift
//  
//
//  Created by Yehor Popovych on 10/8/20.
//

import Foundation
import ScaleCodec
import xxHash_Swift
import CBlake2b

public protocol Hasher {
    static var byteLength: Int { get }
    static var isConcat: Bool { get }
    static var hasher: Hasher { get }
    
    func hash(data: Data) -> Data
}

public protocol NormalHasher: Hasher {
    static var bitWidth: Int { get }
}

extension NormalHasher {
    public static var isConcat: Bool { return false }
    public static var byteLength: Int { return bitWidth / 8 }
}

public protocol ConcatHasher: Hasher {
    static var hashPartBitWidth: Int { get }
}

extension ConcatHasher {
    public static var isConcat: Bool { return true }
    public static var byteLength: Int { return hashPartBitWidth / 8 }
}

public struct HBlake2b128: NormalHasher {
    public func hash(data: Data) -> Data {
        return blake2bHash(data: data, bitWidth: Self.bitWidth)
    }
    
    public static let bitWidth: Int = 128
    public static var hasher: Hasher = HBlake2b128()
}

public struct HBlake2b128Concat: ConcatHasher {
    public func hash(data: Data) -> Data {
        return blake2bHash(data: data, bitWidth: Self.hashPartBitWidth) + data
    }
    
    public static let hashPartBitWidth: Int = 128
    public static var hasher: Hasher = HBlake2b128Concat()
}

public struct HBlake2b256: NormalHasher {
    public func hash(data: Data) -> Data {
        return blake2bHash(data: data, bitWidth: Self.bitWidth)
    }
    
    public static let bitWidth: Int = 256
    public static var hasher: Hasher = HBlake2b256()
}

public struct HBlake2b512: NormalHasher {
    public func hash(data: Data) -> Data {
        return blake2bHash(data: data, bitWidth: Self.bitWidth)
    }
    
    public static let bitWidth: Int = 512
    public static var hasher: Hasher = HBlake2b512()
}

public struct HXX64Concat: ConcatHasher {
    public func hash(data: Data) -> Data {
        return xxHash(data: data, bitWidth: Self.hashPartBitWidth) + data
    }
    
    public static let hashPartBitWidth: Int = 64
    public static var hasher: Hasher = HXX64Concat()
}

public struct HXX128: NormalHasher {
    public func hash(data: Data) -> Data {
        return xxHash(data: data, bitWidth: Self.bitWidth)
    }
    
    public static let bitWidth: Int = 128
    public static var hasher: Hasher = HXX128()
}

public struct HXX256: NormalHasher {
    public func hash(data: Data) -> Data {
        return xxHash(data: data, bitWidth: Self.bitWidth)
    }
    
    public static let bitWidth: Int = 256
    public static var hasher: Hasher = HXX256()
}

public struct HIdentity: ConcatHasher {
    public func hash(data: Data) -> Data {
        return data
    }
    
    public static let hashPartBitWidth: Int = 0
    public static var hasher: Hasher = HIdentity()
}

private func xxHash(data: Data, bitWidth: Int) -> Data {
    var result = Data()
    result.reserveCapacity(bitWidth / 8)
    let chunks = bitWidth / 64
    for seed in 0..<chunks {
        let uint = XXH64.digest(data, seed: UInt64(seed))
        withUnsafeBytes(of: uint.littleEndian) { bytes in
            result.append(contentsOf: bytes)
        }
    }
    return result
}

private func blake2bHash(data: Data, bitWidth: Int, key: Data? = nil) -> Data {
    let count = bitWidth / 8 > BLAKE2B_OUTBYTES.rawValue
        ? Int(BLAKE2B_OUTBYTES.rawValue)
        : bitWidth / 8
    var result = Data(repeating: 0, count: count)
    
    let _ = result.withUnsafeMutableBytes { out -> Int32 in
        data.withUnsafeBytes { dataBytes -> Int32 in
            if let key = key {
                return key.withUnsafeBytes { keyBytes -> Int32 in
                    blake2b(
                        out.baseAddress, out.count, dataBytes.baseAddress, dataBytes.count,
                        keyBytes.baseAddress, keyBytes.count
                    )
                }
            } else {
                return blake2b(
                    out.baseAddress, out.count, dataBytes.baseAddress, dataBytes.count, nil, 0
                )
            }
        }
    }
    
    return result
}
