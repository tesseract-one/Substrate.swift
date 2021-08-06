//
//  KeyTypeId.swift
//  
//
//  Created by Yehor Popovych on 06.08.2021.
//

import Foundation

public struct KeyTypeId {
    public let id: (UInt8, UInt8, UInt8, UInt8)
    
    public init(id: (UInt8, UInt8, UInt8, UInt8)) {
        self.id = id
    }
}

extension KeyTypeId: Equatable {
    public static func == (lhs: KeyTypeId, rhs: KeyTypeId) -> Bool {
        lhs.id.0 == rhs.id.0 && lhs.id.1 == rhs.id.1
            && lhs.id.2 == rhs.id.2 && lhs.id.3 == rhs.id.3
    }
}

extension KeyTypeId: Hashable {
    public func hash(into hasher: inout Swift.Hasher) {
        hasher.combine(id.0)
        hasher.combine(id.1)
        hasher.combine(id.2)
        hasher.combine(id.3)
    }
}

extension KeyTypeId: RawRepresentable {
    public typealias RawValue = String
    
    public init?(rawValue: Self.RawValue) {
        guard let ascii = rawValue.data(using: .ascii) else {
            return nil
        }
        guard ascii.count == 4 else {
            return nil
        }
        self.init(id: (ascii[0], ascii[1], ascii[2], ascii[3]))
    }
    
    public var rawValue: Self.RawValue {
        String(data: Data([id.0, id.1, id.2, id.3]), encoding: .ascii)!
    }
}

extension KeyTypeId {
    /// Key type for Babe module, built-in.
    public static let babe = KeyTypeId(rawValue: "babe")!
    /// Key type for Grandpa module, built-in.
    public static let grandpa = KeyTypeId(rawValue: "gran")!
    /// Key type for controlling an account in a Substrate runtime, built-in.
    public static let account = KeyTypeId(rawValue: "acco")!
    /// Key type for Aura module, built-in.
    public static let aura = KeyTypeId(rawValue: "aura")!
    /// Key type for ImOnline module, built-in.
    public static let imOnline = KeyTypeId(rawValue: "imon")!
    /// Key type for AuthorityDiscovery module, built-in.
    public static let authorityDiscovery = KeyTypeId(rawValue: "audi")!
    /// A key type ID useful for tests.
    public static let dummy = KeyTypeId(rawValue: "dumy")!
}
