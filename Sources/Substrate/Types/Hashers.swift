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
    var hashPartByteLength: Int { get }
    var isConcat: Bool { get }
    var name: String { get }
    
    func hash(data: Data) -> Data
}

public protocol StaticHasher: Hasher {
    static var name: String { get }
    static var instance: Self { get }
}

public extension StaticHasher {
    @inlinable var name: String { Self.name }
}

public protocol FixedHasher: Hasher {
    associatedtype THash: Hash
    
    func hash(data: Data) -> THash
    
    var bitWidth: Int { get }
}

extension FixedHasher {
    public var isConcat: Bool { return false }
    public var hashPartByteLength: Int { return bitWidth / 8 }
    
    @inlinable
    public func hash(data: Data) -> THash {
        return try! THash(hash(data: data))
    }
}

public protocol StaticFixedHasher: FixedHasher, StaticHasher where THash: StaticHash {
    static var bitWidth: Int { get }
}

extension StaticFixedHasher {
    public var bitWidth: Int { Self.bitWidth }
}

public protocol ConcatHasher: Hasher {
    var hashPartBitWidth: Int { get }
}

extension ConcatHasher {
    public var isConcat: Bool { return true }
    public var hashPartByteLength: Int { return hashPartBitWidth / 8 }
}

public protocol StaticConcatHasher: ConcatHasher, StaticHasher {
    static var hashPartBitWidth: Int { get }
}

extension StaticConcatHasher {
    public var hashPartBitWidth: Int { Self.hashPartBitWidth }
}

public struct HBlake2b128: StaticFixedHasher {
    public typealias THash = Hash128
    
    @inlinable
    public func hash(data: Data) -> Data {
        return try! Blake2.hash(.b2b, size: Self.bitWidth / 8, data: data)
    }
    
    public static let name = "Blake2_128"
    public static let bitWidth: Int = 128
    public static let instance = Self()
}

public struct HBlake2b128Concat: StaticConcatHasher {
    @inlinable
    public func hash(data: Data) -> Data {
        return try! Blake2.hash(.b2b, size: Self.hashPartBitWidth / 8, data: data) + data
    }
    
    public static let name = "Blake2_128Concat"
    public static let hashPartBitWidth: Int = 128
    public static let instance = Self()
}

public struct HBlake2b256: StaticFixedHasher {
    public typealias THash = Hash256
    
    @inlinable
    public func hash(data: Data) -> Data {
        return try! Blake2.hash(.b2b, size: Self.bitWidth / 8, data: data)
    }
    
    public static let name = "Blake2_256"
    public static let bitWidth: Int = 256
    public static let instance = Self()
}

public struct HBlake2b512: StaticFixedHasher {
    public typealias THash = Hash512
    
    @inlinable
    public func hash(data: Data) -> Data {
        return try! Blake2.hash(.b2b, size: Self.bitWidth / 8, data: data)
    }
    
    public static let name = "Blake2_512"
    public static let bitWidth: Int = 512
    public static let instance = Self()
}

public struct HXX64Concat: StaticConcatHasher {
    public func hash(data: Data) -> Data {
        return xxHash(data: data, bitWidth: Self.hashPartBitWidth) + data
    }
    
    public static let name = "Twox64Concat"
    public static let hashPartBitWidth: Int = 64
    public static let instance = Self()
}

public struct HXX128: StaticFixedHasher {
    public typealias THash = Hash128
    
    public func hash(data: Data) -> Data {
        return xxHash(data: data, bitWidth: Self.bitWidth)
    }
    
    public static let name = "Twox128"
    public static let bitWidth: Int = 128
    public static let instance = Self()
}

public struct HXX256: StaticFixedHasher {
    public typealias THash = Hash256
    
    public func hash(data: Data) -> Data {
        return xxHash(data: data, bitWidth: Self.bitWidth)
    }
    
    public static let name = "Twox256"
    public static let bitWidth: Int = 256
    public static let instance = Self()
}

public struct HIdentity: StaticConcatHasher {
    @inlinable
    public func hash(data: Data) -> Data {
        return data
    }
    
    public static let name = "Identity"
    public static let hashPartBitWidth: Int = 0
    public static let instance = Self()
}

public struct AnyFixedHasher: FixedHasher {
    public enum HashType {
        case blake2b128
        case blake2b256
        case blake2b512
        case xx128
        case xx256
        
        public init?(name: String) {
            switch name.lowercased() {
            case "blake2b128", "blaketwo128": self = .blake2b128
            case "blake2b256", "blaketwo256": self = .blake2b256
            case "blake2b512", "blaketwo512": self = .blake2b512
            case "xx128", "twox128": self = .xx128
            case "xx256", "twox256": self = .xx256
            default: return nil
            }
        }
        
        public var hasher: any Hasher {
            switch self {
            case .xx256: return HXX256.instance
            case .xx128: return HXX128.instance
            case .blake2b128: return HBlake2b128.instance
            case .blake2b256: return HBlake2b256.instance
            case .blake2b512: return HBlake2b512.instance
            }
        }
    }
    
    public typealias THash = AnyHash
    
    public let hasher: any Hasher
    
    public init?(name: String) {
        guard let type = HashType(name: name) else {
            return nil
        }
        self.init(type: type)
    }
    
    public init(type: HashType) {
        self.hasher = type.hasher
    }
    
    @inlinable
    public var name: String { hasher.name }
    @inlinable
    public var hashPartByteLength: Int { hasher.hashPartByteLength }
    @inlinable
    public var bitWidth: Int { hasher.hashPartByteLength * 8 }
    @inlinable
    public func hash(data: Data) -> Data { hasher.hash(data: data) }
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
