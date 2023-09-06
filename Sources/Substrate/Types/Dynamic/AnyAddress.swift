//
//  AnyAddress.swift
//  
//
//  Created by Yehor Popovych on 14/07/2023.
//

import Foundation
import ScaleCodec

public enum AnyAddress<Id: AccountId>: Address, CustomStringConvertible {
    public typealias TAccountId = Id
    
    case id(Id)
    case other(name: String, values: [any ValueRepresentable])
    
    public init<D: ScaleCodec.Decoder>(
        from decoder: inout D, as info: NetworkType.Info, runtime: any Runtime
    ) throws {
        switch info.type.flatten(runtime).definition {
        case .variant(variants: let vars):
            let idVar = try Self.findIdVariant(in: vars, type: info.type).get()
            if try decoder.peek() == idVar.index {
                let _ = try decoder.decode(.enumCaseId)
                self = try .id(Id(from: &decoder, as: idVar.fields.first!.type, runtime: runtime))
            } else {
                let val = try Value<NetworkType.Id>(from: &decoder, as: info, runtime: runtime)
                    .flatten(runtime: runtime)
                self = .other(name: val.variant!.name, values: val.variant!.values)
            }
        default:
            self = try .id(Id(from: &decoder, as: info, runtime: runtime))
        }
    }
    
    public init(accountId: Id, runtime: Runtime, id: NetworkType.LazyId) throws {
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
        in encoder: inout E, as info: NetworkType.Info, runtime: any Runtime
    ) throws {
        try asValue(runtime: runtime, type: info).encode(in: &encoder, as: info, runtime: runtime)
    }
    
    public func asValue(runtime: Runtime, type info: NetworkType.Info) throws -> Value<NetworkType.Id> {
        switch info.type.flatten(runtime).definition {
        case .variant(variants: let vars):
            switch self {
            case .id(let id):
                let idVar = try Self.findIdVariant(in: vars, type: info.type).get()
                return try .variant(
                    name: idVar.name,
                    values: [id.asValue(runtime: runtime, type: idVar.fields.first!.type)],
                    info.id
                )
            case .other(name: let n, values: let params):
                guard let item = vars.first(where: { $0.name == n }) else {
                    throw TypeError.variantNotFound(for: Self.self, variant: n, in: info.type)
                }
                guard item.fields.count == params.count else {
                    throw TypeError.wrongVariantFieldsCount(for: Self.self, variant: n,
                                                            expected: params.count, in: info.type)
                }
                let mapped = try zip(item.fields, params).map {
                    try $1.asValue(runtime: runtime, type: $0.type)
                }
                return .variant(name: n, values: mapped, info.id)
            }
        default:
            guard case .id(let id) = self else {
                throw TypeError.wrongType(for: Self.self, got: info.type,
                                          reason: "primitive type but self is not Id")
            }
            return try id.asValue(runtime: runtime, type: info)
        }
    }
    
    public static func findIdVariant(
        in vars: [NetworkType.Variant], type: NetworkType
    ) -> Result<NetworkType.Variant, TypeError> {
        for item in vars {
            if item.fields.count != 1 { continue }
            if item.name.lowercased().contains("id") { return .success(item) }
            if item.fields.first?.typeName?.lowercased().contains("id") ?? false {
                return .success(item)
            }
        }
        return .failure(.variantNotFound(for: Self.self, variant: "Id", in: type))
    }
    
    public static func validate(runtime: any Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        switch info.type.flatten(runtime).definition {
        case .variant(variants: let vars):
            return findIdVariant(in: vars, type: info.type).flatMap { variant in
                TAccountId.validate(runtime: runtime, type: variant.fields.first!.type).map{_ in}
            }
        default:
            return TAccountId.validate(runtime: runtime, type: info)
        }
    }
    
    public var description: String {
        switch self {
        case .id(let acc): return "\(acc)"
        case .other(name: let n, values: let v): return "\(n)(\(v))"
        }
    }
}
