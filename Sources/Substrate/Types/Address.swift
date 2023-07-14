//
//  Address.swift
//  
//
//  Created by Yehor Popovych on 21.04.2023.
//

import Foundation

import Foundation
import ScaleCodec

public protocol Address<TAccountId>: RuntimeDynamicCodable, ValueRepresentable {
    associatedtype TAccountId: AccountId
    
    init(accountId: TAccountId,
         runtime: any Runtime,
         id: @escaping RuntimeType.LazyId) throws
}

public protocol StaticAddress<TAccountId>: Address, RuntimeCodable {
    init(accountId: TAccountId, runtime: any Runtime) throws
}

public extension StaticAddress {
    @inlinable
    init(accountId: TAccountId,
         runtime: any Runtime,
         id: @escaping RuntimeType.LazyId) throws
    {
        try self.init(accountId: accountId, runtime: runtime)
    }
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
    public func asValue(runtime: Runtime, type: RuntimeType.Id) throws -> Value<RuntimeType.Id> {
        guard let info = runtime.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        let selfvars: Set<String> = ["Id", "Index", "Address20", "Raw", "Address32"]
        guard case .variant(variants: let variants) = info.definition.flatten(metadata: runtime.metadata) else {
            throw ValueRepresentableError.wrongType(got: info, for: "MultiAddress")
        }
        guard selfvars == Set(variants.map{$0.name}) else {
            throw ValueRepresentableError.wrongType(got: info, for: "MultiAddress")
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

public enum AnyAddress<Id: AccountId>: Address, CustomStringConvertible {
    public typealias TAccountId = Id
    
    case id(Id)
    case other(name: String, values: [any ValueRepresentable])
    
    public init<D: ScaleCodec.Decoder>(
        from decoder: inout D, as type: RuntimeType.Id, runtime: any Runtime
    ) throws {
        guard let info = runtime.resolve(type: type) else {
            throw Value<Void>.DecodingError.typeNotFound(type)
        }
        switch info.flatten(metadata: runtime.metadata).definition {
        case .variant(variants: let vars):
            let idVar = try Self.findIdVariant(in: vars, type: info)
            if try decoder.peek() == idVar.index {
                let _ = try decoder.decode(.enumCaseId)
                self = try .id(Id(from: &decoder, as: idVar.fields.first!.type, runtime: runtime))
            } else {
                let val = try Value<RuntimeType.Id>(from: &decoder, as: type, runtime: runtime)
                self = .other(name: val.variant!.name, values: val.variant!.values)
            }
        default:
            self = try .id(Id(from: &decoder, as: type, runtime: runtime))
        }
    }
    
    public init(accountId: Id, runtime: Runtime, id: @escaping RuntimeType.LazyId) throws {
        self = .id(accountId)
    }
    
    public init(id: Id) {
        self = .id(id)
    }
    
    public init(other name: String, values: [any ValueRepresentable]) {
        self = .other(name: name, values: values)
    }
    
    public var values: [any ValueRepresentable] {
        switch self {
        case .id(let id): return [id]
        case .other(name: _, values: let v): return v
        }
    }
    
    public func encode<E: ScaleCodec.Encoder>(
        in encoder: inout E, as type: RuntimeType.Id, runtime: any Runtime
    ) throws {
        try asValue(runtime: runtime, type: type).encode(in: &encoder, as: type, runtime: runtime)
    }
    
    public func asValue(runtime: Runtime, type: RuntimeType.Id) throws -> Value<RuntimeType.Id> {
        guard let info = runtime.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        switch info.flatten(metadata: runtime.metadata).definition {
        case .variant(variants: let vars):
            switch self {
            case .id(let id):
                let idVar = try Self.findIdVariant(in: vars, type: info)
                return try .variant(
                    name: idVar.name,
                    values: [id.asValue(runtime: runtime, type: idVar.fields.first!.type)],
                    type
                )
            case .other(name: let n, values: let params):
                guard let item = vars.first(where: { $0.name == n }) else {
                    throw ValueRepresentableError.variantNotFound(name: n, in: info)
                }
                guard item.fields.count == params.count else {
                    throw ValueRepresentableError.wrongValuesCount(in: info,
                                                                   expected: params.count,
                                                                   for: n)
                }
                let mapped = try zip(item.fields, params).map {
                    try $1.asValue(runtime: runtime, type: $0.type)
                }
                return .variant(name: n, values: mapped, type)
            }
        default:
            guard case .id(let id) = self else {
                throw ValueRepresentableError.wrongType(got: info, for: "AnyAddress")
            }
            return try id.asValue(runtime: runtime, type: type)
        }
    }
    
    public static func findIdVariant(in vars: [RuntimeType.VariantItem],
                                     type: RuntimeType) throws -> RuntimeType.VariantItem {
        for item in vars {
            if item.fields.count != 1 { continue }
            if item.name.lowercased().contains("id") { return item }
            if item.fields.first?.typeName?.lowercased().contains("id") ?? false { return item }
        }
        throw ValueRepresentableError.wrongType(got: type, for: "AnyAddress")
    }
    
    public var description: String {
        switch self {
        case .id(let acc): return "\(acc)"
        case .other(name: let n, values: let v): return "\(n)(\(v))"
        }
    }
}
