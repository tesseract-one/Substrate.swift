//
//  Hashers.swift
//  
//
//  Created by Yehor Popovych on 10/8/20.
//

import Foundation
import ScaleCodec
import xxHash_Swift
import Blake2

public protocol Hasher {
    static var hashPartByteLength: Int { get }
    static var isConcat: Bool { get }
    static var hasher: any Hasher { get }
    
    var hashPartByteLength: Int { get }
    var isConcat: Bool { get }
    func hash(data: Data) -> Data
}

extension Hasher {
    public var hashPartByteLength: Int { Self.hashPartByteLength }
    public var isConcat: Bool { Self.isConcat }
}

public protocol NormalHasher: Hasher {
    associatedtype THash: Hash
    
    static var bitWidth: Int { get }
}

extension NormalHasher {
    public static var isConcat: Bool { return false }
    public static var hashPartByteLength: Int { return bitWidth / 8 }
}

public protocol ConcatHasher: Hasher {
    static var hashPartBitWidth: Int { get }
}

extension ConcatHasher {
    public static var isConcat: Bool { return true }
    public static var hashPartByteLength: Int { return hashPartBitWidth / 8 }
}

public struct HBlake2b128: NormalHasher {
    public typealias THash = Hash128
    
    public func hash(data: Data) -> Data {
        return try! Blake2.hash(.b2b, size: Self.bitWidth / 8, data: data)
    }
    
    public static let bitWidth: Int = 128
    public static var hasher: Hasher = HBlake2b128()
}

public struct HBlake2b128Concat: ConcatHasher {
    public func hash(data: Data) -> Data {
        return try! Blake2.hash(.b2b, size: Self.hashPartBitWidth / 8, data: data) + data
    }
    
    public static let hashPartBitWidth: Int = 128
    public static var hasher: Hasher = HBlake2b128Concat()
}

public struct HBlake2b256: NormalHasher {
    public typealias THash = Hash256
    
    public func hash(data: Data) -> Data {
        return try! Blake2.hash(.b2b, size: Self.bitWidth / 8, data: data)
    }
    
    public static let bitWidth: Int = 256
    public static var hasher: Hasher = HBlake2b256()
}

public struct HBlake2b512: NormalHasher {
    public typealias THash = Hash512
    
    public func hash(data: Data) -> Data {
        return try! Blake2.hash(.b2b, size: Self.bitWidth / 8, data: data)
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
    public typealias THash = Hash128
    
    public func hash(data: Data) -> Data {
        return xxHash(data: data, bitWidth: Self.bitWidth)
    }
    
    public static let bitWidth: Int = 128
    public static var hasher: Hasher = HXX128()
}

public struct HXX256: NormalHasher {
    public typealias THash = Hash256
    
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
