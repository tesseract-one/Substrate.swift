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
        from decoder: inout D, as type: TypeDefinition, runtime: any Runtime
    ) throws {
        let flat = type.flatten()
        switch flat.definition {
        case .variant(variants: let vars):
            let idVar = try Self.findIdVariant(in: vars, type: flat).get()
            if try decoder.peek() == idVar.index {
                let _ = try decoder.decode(.enumCaseId)
                self = try .id(Id(from: &decoder, as: idVar.fields.first!.type, runtime: runtime))
            } else {
                let val = try Value<TypeDefinition>(from: &decoder, as: flat, runtime: runtime).flatten()
                self = .other(name: val.variant!.name, values: val.variant!.values)
            }
        default:
            self = try .id(Id(from: &decoder, as: type, runtime: runtime))
        }
    }
    
    public init(accountId: Id, runtime: Runtime, type: TypeDefinition.Lazy) throws {
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
        in encoder: inout E, as type: TypeDefinition, runtime: any Runtime
    ) throws {
        try asValue(runtime: runtime, type: type).encode(in: &encoder, runtime: runtime)
    }
    
    public func asValue(runtime: Runtime, type: TypeDefinition) throws -> Value<TypeDefinition> {
        let flat = type.flatten()
        switch flat.definition {
        case .variant(variants: let vars):
            switch self {
            case .id(let id):
                let idVar = try Self.findIdVariant(in: vars, type: flat).get()
                return try .variant(
                    name: idVar.name,
                    values: [id.asValue(runtime: runtime, type: idVar.fields.first!.type)],
                    type
                )
            case .other(name: let n, values: let params):
                guard let item = vars.first(where: { $0.name == n }) else {
                    throw TypeError.variantNotFound(for: Self.self, variant: n,
                                                    type: type, .get())
                }
                guard item.fields.count == params.count else {
                    throw TypeError.wrongVariantFieldsCount(for: Self.self, variant: n,
                                                            expected: params.count,
                                                            type: type, .get())
                }
                let mapped = try zip(item.fields, params).map {
                    try $1.asValue(runtime: runtime, type: $0.type)
                }
                return .variant(name: n, values: mapped, type)
            }
        default:
            guard case .id(let id) = self else {
                throw TypeError.wrongType(for: Self.self, type: type,
                                          reason: "primitive type but self is not Id", .get())
            }
            return try id.asValue(runtime: runtime, type: type)
        }
    }
    
    public static func findIdVariant(
        in vars: [TypeDefinition.Variant], type: TypeDefinition
    ) -> Result<TypeDefinition.Variant, TypeError> {
        for item in vars {
            if item.fields.count != 1 { continue }
            if item.name.lowercased().contains("id") { return .success(item) }
            if item.fields.first?.type.name.lowercased().contains("id") ?? false {
                return .success(item)
            }
        }
        return .failure(.variantNotFound(for: Self.self, variant: "Id", type: type, .get()))
    }
    
    public static func validate(type: TypeDefinition) -> Result<Void, TypeError>
    {
        let flat = type.flatten()
        switch flat.definition {
        case .variant(variants: let vars):
            return findIdVariant(in: vars, type: flat).flatMap { variant in
                TAccountId.validate(type: variant.fields.first!.type).map{_ in}
            }
        default:
            return TAccountId.validate(type: flat)
        }
    }
    
    public var description: String {
        switch self {
        case .id(let acc): return "\(acc)"
        case .other(name: let n, values: let v): return "\(n)(\(v))"
        }
    }
}
