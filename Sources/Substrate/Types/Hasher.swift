//
//  Hasher.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation

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
    
    func hash(data: Data, runtime: any Runtime) throws -> THash
    
    var bitWidth: Int { get }
}

public extension FixedHasher {
    @inlinable var isConcat: Bool { return false }
    @inlinable var hashPartByteLength: Int { return bitWidth / 8 }
}

public protocol StaticFixedHasher: FixedHasher, StaticHasher where THash: StaticHash {
    func hash(data: Data) -> THash
    static var bitWidth: Int { get }
}

public extension StaticFixedHasher {
    @inlinable var bitWidth: Int { Self.bitWidth }
    
    @inlinable func hash(data: Data) -> Data {
        hash(data: data).raw
    }
    
    @inlinable func hash(data: Data, runtime: any Runtime) throws -> THash {
        hash(data: data)
    }
}

public protocol ConcatHasher: Hasher {
    var hashPartBitWidth: Int { get }
}

public extension ConcatHasher {
    @inlinable var isConcat: Bool { return true }
    @inlinable var hashPartByteLength: Int { return hashPartBitWidth / 8 }
}

public protocol StaticConcatHasher: ConcatHasher, StaticHasher {
    static var hashPartBitWidth: Int { get }
}

public extension StaticConcatHasher {
    @inlinable var hashPartBitWidth: Int { Self.hashPartBitWidth }
}
