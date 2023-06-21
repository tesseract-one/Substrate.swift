//
//  Address.swift
//  
//
//  Created by Yehor Popovych on 21.04.2023.
//

import Foundation

import Foundation
import ScaleCodec

public protocol Address: ScaleRuntimeCodable,
                         ScaleRuntimeDynamicDecodable,
                         ScaleRuntimeDynamicEncodable,
                         ValueRepresentable
{
    associatedtype TAccountId: AccountId
    
    init(accountId: TAccountId, runtime: any Runtime) throws
}

public enum MultiAddress<Id: AccountId & Hashable,
                         Index: CompactCodable & Hashable & ValueRepresentable>: Equatable, Hashable {
    case id(Id)
    case index(Index)
    case raw(Data)
    case address32(Data)
    case address20(Data)

    public var isId: Bool {
        switch self {
        case .id(_): return true
        default: return false
        }
    }
    
    public init(id: Id) {
        self = .id(id)
    }

    public init(index: Index) {
        self = .index(index)
    }
}

extension MultiAddress: ValueRepresentable {
    public func asValue() throws -> Value<Void> {
        switch self {
        case .id(let id): return try .variant(name: "Id", values: [id.asValue()])
        case .index(let index): return try .variant(name: "Index", values: [index.asValue()])
        case .address20(let data): return .variant(name: "Address20", values: [.bytes(data)])
        case .raw(let data): return .variant(name: "Raw", values: [.bytes(data)])
        case .address32(let data): return .variant(name: "Address32", values: [.bytes(data)])
        }
    }
}

extension MultiAddress: Address {
    public typealias TAccountId = Id
    
    public init(accountId: Id, runtime: Runtime) throws {
        self.init(id: accountId)
    }
}

extension MultiAddress: ScaleRuntimeCodable {
    public init(from decoder: ScaleDecoder, runtime: any Runtime) throws {
        let type = try decoder.decode(.enumCaseId)
        switch type {
        case 0: self = try .id(Id(from: decoder, runtime: runtime))
        case 1: self = try .index(decoder.decode(.compact))
        case 2: self = try .raw(decoder.decode())
        case 3: self = try .address32(decoder.decode(.fixed(32)))
        case 4: self = try .address20(decoder.decode(.fixed(20)))
        default: throw decoder.enumCaseError(for: type)
        }
    }

    public func encode(in encoder: ScaleEncoder, runtime: any Runtime) throws {
        switch self {
        case .id(let id): try id.encode(in: encoder.encode(0, .enumCaseId), runtime: runtime)
        case .index(let index): try encoder.encode(1, .enumCaseId).encode(index, .compact)
        case .raw(let data): try encoder.encode(2, .enumCaseId).encode(data)
        case .address32(let data): try encoder.encode(3, .enumCaseId).encode(data, .fixed(32))
        case .address20(let data): try encoder.encode(4, .enumCaseId).encode(data, .fixed(20))
        }
    }
}
