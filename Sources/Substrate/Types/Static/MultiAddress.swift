//
//  MultiAddress.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec

public enum MultiAddress<Id, Index>: Equatable, Hashable
    where Index: CompactCodable & Hashable & ValueRepresentable & RuntimeDynamicValidatable,
          Id: AccountId & Hashable
{
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
    
    @inlinable
    public static var allCases: [String] { ["Id", "Index", "Address20", "Raw", "Address32"] }
}

extension MultiAddress: ValueRepresentable {
    public func asValue(runtime: Runtime, type: RuntimeType.Id) throws -> Value<RuntimeType.Id> {
        guard let info = runtime.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        guard case .variant(variants: let variants) = info.flatten(runtime).definition else {
            throw ValueRepresentableError.wrongType(got: info, for: "MultiAddress")
        }
        if let badCase = Set(Self.allCases).symmetricDifference(variants.map{$0.name}).first {
            throw ValueRepresentableError.variantNotFound(name: badCase, in: info)
        }
        switch self {
        case .id(let id):
            guard let field = variants.first(where: {$0.name == "Id"})?.fields.first else {
                throw ValueRepresentableError.wrongType(got: info, for: "MultiAddress")
            }
            return try .variant(name: "Id",
                                values: [id.asValue(runtime: runtime, type: field.type)],
                                type)
        case .index(let index):
            guard let field = variants.first(where: {$0.name == "Index"})?.fields.first else {
                throw ValueRepresentableError.wrongType(got: info, for: "MultiAddress")
            }
            return try .variant(name: "Index",
                                values: [index.asValue(runtime: runtime, type: field.type)],
                                type)
        case .address20(let data):
            guard let field = variants.first(where: {$0.name == "Address20"})?.fields.first else {
                throw ValueRepresentableError.wrongType(got: info, for: "MultiAddress")
            }
            return try .variant(name: "Address20",
                                values: [data.asValue(runtime: runtime, type: field.type)],
                                type)
        case .raw(let data):
            guard let field = variants.first(where: {$0.name == "Raw"})?.fields.first else {
                throw ValueRepresentableError.wrongType(got: info, for: "MultiAddress")
            }
            return try .variant(name: "Raw",
                                values: [data.asValue(runtime: runtime, type: field.type)],
                                type)
        case .address32(let data):
            guard let field = variants.first(where: {$0.name == "Address32"})?.fields.first else {
                throw ValueRepresentableError.wrongType(got: info, for: "MultiAddress")
            }
            return try .variant(name: "Address32",
                                values: [data.asValue(runtime: runtime, type: field.type)],
                                type)
        }
    }
}

extension MultiAddress: VoidValueRepresentable where
    Id: VoidValueRepresentable, Index: VoidValueRepresentable
{
    public func asValue() -> Value<Void> {
        switch self {
        case .id(let id): return .variant(name: "Id", values: [id.asValue()])
        case .index(let index): return .variant(name: "Index", values: [index.asValue()])
        case .address20(let data): return .variant(name: "Address20", values: [data.asValue()])
        case .raw(let data): return .variant(name: "Raw", values: [data.asValue()])
        case .address32(let data): return .variant(name: "Address32", values: [data.asValue()])
        }
    }
}

extension MultiAddress: StaticAddress {
    public typealias TAccountId = Id
    
    public init(accountId: Id, runtime: Runtime) throws {
        self.init(id: accountId)
    }
}

extension MultiAddress: RuntimeDynamicValidatable {
    public static func validate(runtime: Runtime,
                                type id: RuntimeType.Id) -> Result<Void, DynamicValidationError>
    {
        guard let info = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(id))
        }
        guard case .variant(variants: let variants) = info.flatten(runtime).definition else {
            return .failure(.wrongType(got: info, for: "MultiAddress"))
        }
        if let badCase = Set(allCases).symmetricDifference(variants.map{$0.name}).first {
            return .failure(.variantNotFound(name: badCase, in: info))
        }
        for variant in variants {
            if variant.fields.count != 1 {
                return .failure(.wrongValuesCount(in: info, expected: 1,
                                                  for: variant.name))
            }
        }
        return .success(())
    }
}

extension MultiAddress: RuntimeCodable {
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: any Runtime) throws {
        let type = try decoder.decode(.enumCaseId)
        switch type {
        case 0: self = try .id(runtime.decode(account: Id.self, from: &decoder))
        case 1: self = try .index(decoder.decode(.compact))
        case 2: self = try .raw(decoder.decode())
        case 3: self = try .address32(decoder.decode(.fixed(32)))
        case 4: self = try .address20(decoder.decode(.fixed(20)))
        default: throw decoder.enumCaseError(for: type)
        }
    }

    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: any Runtime) throws {
        switch self {
        case .id(let id):
            try encoder.encode(0, .enumCaseId)
            try runtime.encode(account: id, in: &encoder)
        case .index(let index):
            try encoder.encode(1, .enumCaseId)
            try encoder.encode(index, .compact)
        case .raw(let data):
            try encoder.encode(2, .enumCaseId)
            try encoder.encode(data)
        case .address32(let data):
            try encoder.encode(3, .enumCaseId)
            try encoder.encode(data, .fixed(32))
        case .address20(let data):
            try encoder.encode(4, .enumCaseId)
            try encoder.encode(data, .fixed(20))
        }
    }
}

extension MultiAddress: CustomStringConvertible {
    public var description: String {
        switch self {
        case .id(let acc): return "\(acc)"
        case .index(let index): return "\(index)"
        case .raw(let raw): return raw.hex()
        case .address20(let raw): return raw.hex()
        case .address32(let raw): return raw.hex()
        }
    }
}
