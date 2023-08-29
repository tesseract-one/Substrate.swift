//
//  Hashers.swift
//  
//
//  Created by Yehor Popovych on 10/8/20.
//

import Foundation
import xxHash
import Blake2

public struct HBlake2b128: StaticFixedHasher, Equatable {
    public typealias THash = Hash128
    
    @inlinable
    public func hash(data: Data) -> THash {
        try! Hash128(raw: Blake2b.hash(size: Self.bitWidth / 8, data: data))
    }
    
    public static let name = "Blake2_128"
    public static let bitWidth: Int = 128
    public static let instance = Self()
}

public struct HBlake2b128Concat: StaticConcatHasher, Equatable {
    @inlinable
    public func hash(data: Data) -> Data {
        try! Blake2b.hash(size: Self.hashPartBitWidth / 8, data: data) + data
    }
    
    public static let name = "Blake2_128Concat"
    public static let hashPartBitWidth: Int = 128
    public static let instance = Self()
}

public struct HBlake2b256: StaticFixedHasher, Equatable {
    public typealias THash = Hash256
    
    @inlinable
    public func hash(data: Data) -> THash {
        try! Hash256(raw: Blake2b.hash(size: Self.bitWidth / 8, data: data))
    }
    
    public static let name = "Blake2_256"
    public static let bitWidth: Int = 256
    public static let instance = Self()
}

public struct HBlake2b512: StaticFixedHasher, Equatable {
    public typealias THash = Hash512
    
    @inlinable
    public func hash(data: Data) -> THash {
        try! Hash512(raw: Blake2b.hash(size: Self.bitWidth / 8, data: data))
    }
    
    public static let name = "Blake2_512"
    public static let bitWidth: Int = 512
    public static let instance = Self()
}

public struct HXX64Concat: StaticConcatHasher, Equatable {
    public func hash(data: Data) -> Data {
        xxHash(data: data, bitWidth: Self.hashPartBitWidth) + data
    }
    
    public static let name = "Twox64Concat"
    public static let hashPartBitWidth: Int = 64
    public static let instance = Self()
}

public struct HXX128: StaticFixedHasher, Equatable {
    public typealias THash = Hash128
    
    public func hash(data: Data) -> THash {
        try! Hash128(raw: xxHash(data: data, bitWidth: Self.bitWidth))
    }
    
    public static let name = "Twox128"
    public static let bitWidth: Int = 128
    public static let instance = Self()
}

public struct HXX256: StaticFixedHasher, Equatable {
    public typealias THash = Hash256
    
    public func hash(data: Data) -> THash {
        try! Hash256(raw: xxHash(data: data, bitWidth: Self.bitWidth))
    }
    
    public static let name = "Twox256"
    public static let bitWidth: Int = 256
    public static let instance = Self()
}

public struct HIdentity: StaticConcatHasher, Equatable {
    @inlinable
    public func hash(data: Data) -> Data {
        return data
    }
    
    public static let name = "Identity"
    public static let hashPartBitWidth: Int = 0
    public static let instance = Self()
}

private func xxHash(data: Data, bitWidth: Int) -> Data {
    var result = Data()
    result.reserveCapacity(bitWidth / 8)
    let chunks = bitWidth / 64
    for seed in 0..<chunks {
        result.append(
            contentsOf: xxHash64.canonical(hash: xxHash64.hash(data, seed: UInt64(seed))).reversed()
        )
    }
    return result
}
