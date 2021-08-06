//
//  CryptoTypeId.swift
//  
//
//  Created by Yehor Popovych on 04.05.2021.
//

import Foundation

public struct CryptoTypeId {
    public let id: (UInt8, UInt8, UInt8, UInt8)
    
    public init(id: (UInt8, UInt8, UInt8, UInt8)) {
        self.id = id
    }
}

extension CryptoTypeId: Equatable {
    public static func == (lhs: CryptoTypeId, rhs: CryptoTypeId) -> Bool {
        lhs.id.0 == rhs.id.0 && lhs.id.1 == rhs.id.1
            && lhs.id.2 == rhs.id.2 && lhs.id.3 == rhs.id.3
    }
}

extension CryptoTypeId: Hashable {
    public func hash(into hasher: inout Swift.Hasher) {
        hasher.combine(id.0)
        hasher.combine(id.1)
        hasher.combine(id.2)
        hasher.combine(id.3)
    }
}

extension CryptoTypeId: RawRepresentable {
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

extension CryptoTypeId {
    public static let ed25519 = CryptoTypeId(rawValue: "ed25")!
    public static let ecdsa = CryptoTypeId(rawValue: "ecds")!
    public static let sr25519 = CryptoTypeId(rawValue: "sr25")!
}

public enum CryptoTypeError: Error {
    //case uknownType(id: String)
    case wrongType(type: CryptoTypeId, expected: [CryptoTypeId])
}
