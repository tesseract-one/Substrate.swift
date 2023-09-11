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
    var type: LatestMetadata.StorageHasher { get }
    
    func hash(data: Data) -> Data
}

public protocol StaticHasher: Hasher, ValidatableType {
    static var hasherType: LatestMetadata.StorageHasher { get }
    static var instance: Self { get }
}

public extension StaticHasher {
    @inlinable var type: LatestMetadata.StorageHasher { Self.hasherType }
    
    static func validate(as type: TypeDefinition,
                         in runtime: any Runtime) -> Result<Void, TypeError>
    {
        guard type.name.hasSuffix(hasherType.name) else {
            return .failure(.wrongType(for: Self.self, type: type,
                                       reason: "Unknown hasher: \(type)", .get()))
        }
        return .success(())
    }
}

public protocol FixedHasher: Hasher, ValidatableType {
    associatedtype THash: Hash
    
    init(type: AnyFixedHasher.HashType?) throws
    
    func hash(data: Data, runtime: any Runtime) throws -> THash
    
    var bitWidth: Int { get }
    var fixedType: AnyFixedHasher.HashType { get }
}

public extension FixedHasher {
    @inlinable var isConcat: Bool { return false }
    @inlinable var hashPartByteLength: Int { return bitWidth / 8 }
}

public protocol StaticFixedHasher: FixedHasher, StaticHasher where THash: StaticHash {
    func hash(data: Data) -> THash
    static var fixedHasherType: AnyFixedHasher.HashType { get }
    static var bitWidth: Int { get }
}

public extension StaticFixedHasher {
    @inlinable var fixedType: AnyFixedHasher.HashType { Self.fixedHasherType }
    @inlinable var bitWidth: Int { Self.bitWidth }
    
    init(type: AnyFixedHasher.HashType?) throws {
        guard type == nil || type == Self.fixedHasherType else {
            throw DynamicTypes.LookupError.wrongType(
                name: "Hasher: \(type!)", reason: "Expected: \(Self.fixedHasherType)"
            )
        }
        self = Self.instance
    }
    
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
