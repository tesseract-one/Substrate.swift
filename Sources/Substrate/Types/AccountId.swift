//
//  AccountId.swift
//  
//
//  Created by Yehor Popovych on 17.04.2023.
//

import Foundation
import ScaleCodec

public protocol AccountId: ScaleRuntimeDynamicEncodable, ScaleRuntimeDynamicDecodable, Codable {
    init(from string: String) throws
    init(pub: PublicKey) throws
    init(raw: Data) throws
    
    var raw: Data { get }
    
    func toString(runtime: any Runtime) -> String
}

public extension AccountId {
    init(from string: String) throws {
        let (raw, _) = try SS58.decode(string: string)
        try self.init(raw: raw)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let u8arr = try? container.decode([UInt8].self) {
            try self.init(raw: Data(u8arr))
        } else if let data = try? container.decode(Data.self) {
            try self.init(raw: data)
        } else {
            let string = try container.decode(String.self)
            try self.init(from: string)
        }
    }
    
    func toString(runtime: any Runtime) -> String {
        SS58.encode(data: raw, format: runtime.addressFormat)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.toString(runtime: encoder.runtime))
    }
}

public protocol StaticAccountId: AccountId, ScaleRuntimeCodable {
    init(checked raw: Data) throws
    
    static var byteCount: Int { get }
}

public extension StaticAccountId {
    init(raw: Data) throws {
        guard raw.count == Self.byteCount else {
            throw SizeMismatchError(size: raw.count, expected: Self.byteCount)
        }
        try self.init(checked: raw)
    }
    
    init(from decoder: ScaleDecoder, runtime: any Runtime) throws {
        let raw = try decoder.decode(.fixed(UInt(Self.byteCount)))
        try self.init(checked: raw)
    }
    
    func encode(in encoder: ScaleEncoder, runtime: any Runtime) throws {
        try encoder.encode(raw, .fixed(UInt(Self.byteCount)))
    }
}

public struct AccountId32: StaticAccountId {
    public let raw: Data
    
    public init(checked raw: Data) throws {
        self.raw = raw
    }
    
    public init(pub: PublicKey) throws {
        switch pub.type {
        case .ed25519, .sr25519:
            try self.init(raw: pub.raw)
        case .ecdsa:
            let hash = HBlake2b256.instance.hash(data: pub.raw)
            try self.init(checked: hash)
        }
    }
    
    public static let byteCount: Int = 32
}
