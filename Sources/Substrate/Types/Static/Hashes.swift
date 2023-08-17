//
//  Hashes.swift
//  
//
//  Created by Yehor Popovych on 10/8/20.
//

import Foundation

public struct Hash128: StaticHash {
    public let raw: Data
    
    public init(raw: Data) throws {
        guard raw.count == Self.fixedBytesCount else {
            throw SizeMismatchError(size: raw.count, expected: Self.fixedBytesCount)
        }
        self.raw = raw
    }
    
    public static var fixedBytesCount: Int = 16
}

public struct Hash160: StaticHash {
    public let raw: Data
    
    public init(raw: Data) throws {
        guard raw.count == Self.fixedBytesCount else {
            throw SizeMismatchError(size: raw.count, expected: Self.fixedBytesCount)
        }
        self.raw = raw
    }
    
    public static var fixedBytesCount: Int = 20
}

public struct Hash256: StaticHash {
    public let raw: Data
    
    public init(raw: Data) throws {
        guard raw.count == Self.fixedBytesCount else {
            throw SizeMismatchError(size: raw.count, expected: Self.fixedBytesCount)
        }
        self.raw = raw
    }
    
    public static var fixedBytesCount: Int = 32
}

public struct Hash512: StaticHash {
    public let raw: Data
    
    public init(raw: Data) throws {
        guard raw.count == Self.fixedBytesCount else {
            throw SizeMismatchError(size: raw.count, expected: Self.fixedBytesCount)
        }
        self.raw = raw
    }
    
    public static var fixedBytesCount: Int = 64
}
