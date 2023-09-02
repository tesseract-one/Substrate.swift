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
        from decoder: inout D, as type: NetworkType.Id, runtime: any Runtime
    ) throws {
        guard let info = runtime.resolve(type: type) else {
            throw Value<NetworkType.Id>.DecodingError.typeNotFound(type)
        }
        switch info.flatten(runtime).definition {
        case .variant(variants: let vars):
            let idVar = try Self.findIdVariant(in: vars, type: info).getValueError()
            if try decoder.peek() == idVar.index {
                let _ = try decoder.decode(.enumCaseId)
                self = try .id(Id(from: &decoder, as: idVar.fields.first!.type, runtime: runtime))
            } else {
                let val = try Value<NetworkType.Id>(from: &decoder, as: type, runtime: runtime)
                    .flatten(runtime: runtime)
                self = .other(name: val.variant!.name, values: val.variant!.values)
            }
        default:
            self = try .id(Id(from: &decoder, as: type, runtime: runtime))
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
        in encoder: inout E, as type: NetworkType.Id, runtime: any Runtime
    ) throws {
        try asValue(runtime: runtime, type: type).encode(in: &encoder, as: type, runtime: runtime)
    }
    
    public func asValue(runtime: Runtime, type: NetworkType.Id) throws -> Value<NetworkType.Id> {
        guard let info = runtime.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        switch info.flatten(runtime).definition {
        case .variant(variants: let vars):
            switch self {
            case .id(let id):
                let idVar = try Self.findIdVariant(in: vars, type: info).getValueError()
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
    
    public static func findIdVariant(
        in vars: [NetworkType.Variant], type: NetworkType
    ) -> Result<NetworkType.Variant, DynamicValidationError> {
        for item in vars {
            if item.fields.count != 1 { continue }
            if item.name.lowercased().contains("id") { return .success(item) }
            if item.fields.first?.typeName?.lowercased().contains("id") ?? false {
                return .success(item)
            }
        }
        return .failure(.variantNotFound(name: "Id", in: type))
    }
    
    public static func validate(runtime: Runtime,
                                type id: NetworkType.Id) -> Result<Void, DynamicValidationError>
    {
        guard let info = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(id))
        }
        switch info.flatten(runtime).definition {
        case .variant(variants: let vars):
            return findIdVariant(in: vars, type: info).flatMap { variant in
                TAccountId.validate(runtime: runtime, type: variant.fields.first!.type)
            }
        default:
            return TAccountId.validate(runtime: runtime, type: id)
        }
    }
    
    public var description: String {
        switch self {
        case .id(let acc): return "\(acc)"
        case .other(name: let n, values: let v): return "\(n)(\(v))"
        }
    }
}
