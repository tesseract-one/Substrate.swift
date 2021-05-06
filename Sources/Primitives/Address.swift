//
//  Address.swift
//  
//
//  Created by Yehor Popovych on 10/8/20.
//

import Foundation
import ScaleCodec

public protocol Address: ScaleDynamicCodable {
    init(pubKey: PublicKey) throws
}

public enum AddressError: Error {
    case unsupportedId(PublicKey)
}

public enum MultiAddress<Id, Index>: Equatable, Hashable
    where
        Id: PublicKey & Hashable & SDefault, Index: CompactCodable & Hashable & SDefault
{
    case id(Id)
    case index(Index)
    case raw(Data)
    case address32(Data)
    case address20(Data)
    
    public var isId: Bool {
        guard case .id(_) = self else {
            return false
        }
        return true
    }
    
    public init(id: Id) {
        self = .id(id)
    }
    
    public init(index: Index) {
        self = .index(index)
    }
}

extension MultiAddress: Address {
    public init(pubKey: PublicKey) throws {
        guard pubKey.typeId == Id.typeId else {
            throw AddressError.unsupportedId(pubKey)
        }
        try self.init(id: Id(bytes: pubKey.bytes, format: pubKey.format))
    }
}

extension MultiAddress: SDefault {
    public static func `default`() -> MultiAddress<Id, Index> {
        MultiAddress(id: .default())
    }
}

extension MultiAddress: ScaleDynamicCodable {
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        let type = try decoder.decode(.enumCaseId)
        switch type {
        case 0: self = try .id(Id(from: decoder, registry: registry))
        case 1: self = try .index(decoder.decode(.compact))
        case 2: self = try .raw(decoder.decode())
        case 3: self = try .address32(decoder.decode(.fixed(32)))
        case 4: self = try .address20(decoder.decode(.fixed(20)))
        default: throw decoder.enumCaseError(for: type)
        }
    }
    
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        switch self {
        case .id(let id): try id.encode(in: encoder.encode(0, .enumCaseId), registry: registry)
        case .index(let index): try encoder.encode(1, .enumCaseId).encode(index, .compact)
        case .raw(let data): try encoder.encode(2, .enumCaseId).encode(data)
        case .address32(let data): try encoder.encode(3, .enumCaseId).encode(data, .fixed(32))
        case .address20(let data): try encoder.encode(4, .enumCaseId).encode(data, .fixed(20))
        }
    }
}
