//
//  Types+ValueRepresentable.swift
//  
//
//  Created by Yehor Popovych on 17.01.2023.
//

import Foundation
import ScaleCodec
import Numberick

public extension FixedWidthInteger where Self: ValidatableTypeDynamic {
    func asValue() -> Value<Void> {
        Self.isSigned ?  .int(Int256(self)) : .uint(UInt256(self))
    }
    
    func asValue(runtime: any Runtime, type info: NetworkType.Info) throws -> Value<NetworkType.Id> {
        try validate(runtime: runtime, type: info).get()
        return Self.isSigned ?  .int(Int256(self), info.id) : .uint(UInt256(self), info.id)
    }
}

extension UInt8: ValueRepresentable, VoidValueRepresentable {}
extension UInt16: ValueRepresentable, VoidValueRepresentable {}
extension UInt32: ValueRepresentable, VoidValueRepresentable {}
extension UInt64: ValueRepresentable, VoidValueRepresentable {}
extension UInt: ValueRepresentable, VoidValueRepresentable {}
extension NBKDoubleWidth: ValueRepresentable, VoidValueRepresentable {}
extension Int8: ValueRepresentable, VoidValueRepresentable {}
extension Int16: ValueRepresentable, VoidValueRepresentable {}
extension Int32: ValueRepresentable, VoidValueRepresentable {}
extension Int64: ValueRepresentable, VoidValueRepresentable {}
extension Int: ValueRepresentable, VoidValueRepresentable {}

extension Value: ValueRepresentable, VoidValueRepresentable {
    public func asValue() -> Value<Void> { mapContext{_ in} }
    
    public func asValue(runtime: any Runtime, type info: NetworkType.Info) throws -> Value<NetworkType.Id> {
        try validate(runtime: runtime, type: info).get()
        return mapContext{_ in info.id}
    }
}

extension Bool: ValueRepresentable, VoidValueRepresentable {
    public func asValue() -> Value<Void> { .bool(self) }
    
    public func asValue(runtime: any Runtime, type info: NetworkType.Info) throws -> Value<NetworkType.Id> {
        try validate(runtime: runtime, type: info).get()
        return .bool(self, info.id)
    }
}

extension String: ValueRepresentable, VoidValueRepresentable {
    public func asValue() -> Value<Void> { .string(self) }
    
    public func asValue(runtime: any Runtime, type info: NetworkType.Info) throws -> Value<NetworkType.Id> {
        try validate(runtime: runtime, type: info).get()
        return .string(self, info.id)
    }
}

extension Data: ValueRepresentable, VoidValueRepresentable {
    public func asValue() -> Value<Void> { .bytes(self) }
    
    public func asValue(runtime: any Runtime, type info: NetworkType.Info) throws -> Value<NetworkType.Id> {
        try validate(runtime: runtime, type: info).get()
        return .bytes(self, info.id)
    }
}

extension Compact: ValueRepresentable, VoidValueRepresentable {
    public func asValue() -> Value<Void> { .uint(UInt256(value.uint)) }
    
    public func asValue(runtime: any Runtime, type info: NetworkType.Info) throws -> Value<NetworkType.Id> {
        try validate(runtime: runtime, type: info).get()
        return .uint(UInt256(value.uint), info.id)
    }
}

extension Character: ValueRepresentable, VoidValueRepresentable {
    public func asValue() -> Value<Void> { .char(self) }
    
    public func asValue(runtime: any Runtime, type info: NetworkType.Info) throws -> Value<NetworkType.Id> {
        try validate(runtime: runtime, type: info).get()
        return .char(self, info.id)
    }
}

public extension Collection where Element == ValueRepresentable {
    func validate(runtime: Runtime, type info: NetworkType.Info) -> Result<Void, TypeError> {
        switch info.type.flatten(runtime).definition {
        case .array(count: let c, of: let eType):
            guard count == c else {
                return .failure(.wrongValuesCount(for: self, expected: count,
                                                  type: info.type, .get()))
            }
            fallthrough
        case .sequence(of: let eType):
            return voidErrorMap { $0.validate(runtime: runtime, type: eType).map{_ in} }
        case .composite(fields: let fields):
            guard count == fields.count else {
                return .failure(.wrongValuesCount(for: self, expected: count,
                                                  type: info.type, .get()))
            }
            return zip(self, fields).voidErrorMap { v, f in
                v.validate(runtime: runtime, type: f.type).map {_ in}
            }
        case .tuple(components: let ids):
            guard count == ids.count else {
                return .failure(.wrongValuesCount(for: self, expected: count,
                                                  type: info.type, .get()))
            }
            return zip(self, ids).voidErrorMap { v, id in
                v.validate(runtime: runtime, type: id).map {_ in}
            }
        default:
            return .failure(.wrongType(for: self, type: info.type,
                                       reason: "Isn't collection", .get()))
        }
    }
    
    func asValue(runtime: any Runtime, type info: NetworkType.Info) throws -> Value<NetworkType.Id> {
        switch info.type.flatten(runtime).definition {
        case .array(count: let count, of: let eType):
            guard count == self.count else {
                throw TypeError.wrongValuesCount(for: self,
                                                 expected: self.count,
                                                 type: info.type, .get())
            }
            fallthrough
        case .sequence(of: let eType):
            let mapped = try map{ try $0.asValue(runtime: runtime, type: eType) }
            return .sequence(mapped, info.id)
        case .composite(fields: let fields):
            guard fields.count == count else {
                throw TypeError.wrongValuesCount(for: self,
                                                 expected: count,
                                                 type: info.type, .get())
            }
            let arr = try zip(self, fields).map { try $0.asValue(runtime: runtime, type: $1.type) }
            return .sequence(arr, info.id)
        case .tuple(components: let ids):
            guard ids.count == count else {
                throw TypeError.wrongValuesCount(for: self,
                                                 expected: count,
                                                 type: info.type, .get())
            }
            let arr = try zip(self, ids).map { try $0.asValue(runtime: runtime, type: $1) }
            return .sequence(arr, info.id)
        default:
            throw TypeError.wrongType(for: self, type: info.type,
                                      reason: "Isn't collection", .get())
        }
    }
}

public extension Sequence where Element == VoidValueRepresentable {
    func asValue() -> Value<Void> {.sequence(self)}
}

extension Array: ValueRepresentable, ValidatableTypeDynamic where Element == ValueRepresentable {}
extension Array: VoidValueRepresentable where Element == VoidValueRepresentable {}

extension Dictionary: ValueRepresentable, ValidatableTypeDynamic where Key == String,
                                                                       Value == ValueRepresentable
{
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        switch info.type.flatten(runtime).definition {
        case .composite(fields: let fields):
            return fields.voidErrorMap { field in
                guard let key = field.name else {
                    return .failure(.wrongType(for: self, type: info.type,
                                               reason: "field name is nil", .get()))
                }
                return self[key].validate(runtime: runtime, type: field.type).map{_ in}
            }
        // Variant can be represented as ["Name": Value]
        case .variant(variants: let variants):
            guard count == 1 else {
                return .failure(.wrongType(for: self, type: info.type,
                                           reason: "count != 1 for variant", .get()))
            }
            guard let variant = variants.first(where: { $0.name == first!.key }) else {
                return .failure(.variantNotFound(for: self,
                                                 variant: first!.key,
                                                 type: info.type, .get()))
            }
            // this will allow array/dictionary as a parameter
            if variant.fields.count == 1 {
                return first!.value.validate(runtime: runtime,
                                             type: variant.fields[0].type).map{_ in}
            }
            // unpack fields
            switch first!.value {
            case let arr as Array<ValueRepresentable>:
                guard variant.fields.count == arr.count else {
                    return .failure(.wrongValuesCount(for: self,
                                                      expected: variant.fields.count,
                                                      type: info.type, .get()))
                }
                return zip(variant.fields, arr).voidErrorMap { field, elem in
                    elem.validate(runtime: runtime, type: field.type).map{_ in}
                }
            case let dict as Dictionary<String, ValueRepresentable>:
                return variant.fields.voidErrorMap { field in
                    guard let key = field.name else {
                        return .failure(.wrongType(for: self, type: info.type,
                                                   reason: "field name is nil", .get()))
                    }
                    return dict[key].validate(runtime: runtime, type: field.type).map{_ in}
                }
            default: return .failure(.wrongType(for: self, type: info.type,
                                                reason: "Can't be a variant type", .get()))
            }
        default:
            return .failure(.wrongType(for: self, type: info.type,
                                       reason: "Isn't map", .get()))
        }
    }
    
    public func asValue(runtime: Runtime,
                        type info: NetworkType.Info) throws -> Substrate.Value<NetworkType.Id>
    {
        switch info.type.flatten(runtime).definition {
        case .composite(fields: let fields):
            let map = try fields.map { field in
                guard let key = field.name else {
                    throw TypeError.wrongType(for: self, type: info.type,
                                              reason: "field name is nil", .get())
                }
                return try (key, self[key].asValue(runtime: runtime, type: field.type))
            }
            return .map(Dictionary<_,_>(uniqueKeysWithValues: map), info.id)
        // Variant can be represented as ["Name": Value]
        case .variant(variants: let variants):
            guard count == 1 else {
                throw TypeError.wrongType(for: self, type: info.type,
                                          reason: "count != 1 for variant", .get())
            }
            guard let variant = variants.first(where: { $0.name == first!.key }) else {
                throw TypeError.variantNotFound(for: self, variant: first!.key,
                                                type: info.type, .get())
            }
            // this will allow array/dictionary as a parameter
            if variant.fields.count == 1 {
                let val = try first!.value.asValue(runtime: runtime,
                                                   type: variant.fields.first!.type)
                if let name = variant.fields.first?.name {
                    return .variant(name: variant.name, fields: [name: val], info.id)
                } else {
                    return .variant(name: variant.name, values: [val], info.id)
                }
            }
            // unpack fields
            switch first!.value {
            case let arr as Array<ValueRepresentable>:
                guard arr.count == variant.fields.count else {
                    throw TypeError.wrongValuesCount(for: self,
                                                     expected: variant.fields.count,
                                                     type: info.type, .get())
                }
                let seq = try zip(arr, variant.fields).map { el, fld in
                    try el.asValue(runtime: runtime, type: fld.type)
                }
                return .variant(name: variant.name, values: seq, info.id)
            case let dict as Dictionary<String, ValueRepresentable>:
                let map = try variant.fields.map { field in
                    guard let key = field.name else {
                        throw TypeError.wrongType(for: self, type: info.type,
                                                  reason: "field name is nil", .get())
                    }
                    return try (key, dict[key].asValue(runtime: runtime, type: field.type))
                }
                return .variant(name: variant.name,
                                fields: Dictionary<_,_>(uniqueKeysWithValues: map), info.id)
            default: throw TypeError.wrongType(for: self, type: info.type,
                                               reason: "Can't be a variant type", .get())
            }
        default:
            throw TypeError.wrongType(for: self, type: info.type,
                                      reason: "Isn't map", .get())
        }
    }
}

extension Dictionary: VoidValueRepresentable where Key: StringProtocol, Value == VoidValueRepresentable {
    public func asValue() -> Substrate.Value<Void> {
        .map(map { (String($0.key), $0.value.asValue()) })
    }
}

extension Optional: ValueRepresentable, ValidatableTypeDynamic where Wrapped == ValueRepresentable {
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        if let value = self {
            if let field = info.type.asOptional(runtime) {
                return value.validate(runtime: runtime, type: field.type).map{_ in}
            }
            return value.validate(runtime: runtime, type: info)
        }
        return info.type.asOptional(runtime) != nil
            ? .success(())
            : .failure(.wrongType(for: Self.self, type: info.type,
                                  reason: "Isn't optional", .get()))
    }
    
    public func asValue(runtime: Runtime, type info: NetworkType.Info) throws -> Value<NetworkType.Id> {
        if let svalue = self {
            if let field = info.type.asOptional(runtime) {
                let value = try svalue.asValue(runtime: runtime, type: field.type)
                return .variant(name: "Some", values: [value], info.id)
            }
            return try svalue.asValue(runtime: runtime, type: info)
        }
        guard info.type.asOptional(runtime) != nil else {
            throw TypeError.wrongType(for: Self.self, type: info.type,
                                      reason: "Isn't optional", .get())
        }
        return .variant(name: "None", values: [], info.id)
    }
}

extension Optional: VoidValueRepresentable where Wrapped == VoidValueRepresentable {
    public func asValue() -> Value<Void> {
        switch self {
        case .some(let val): return .variant(name: "Some", values: [val.asValue()])
        case .none: return .variant(name: "None", values: [])
        }
    }
}

extension Either: ValueRepresentable, ValidatableTypeDynamic
    where Left == ValueRepresentable, Right == ValueRepresentable
{
    public func validate(runtime: Runtime, type info: NetworkType.Info) -> Result<Void, TypeError> {
        guard let result = info.type.asResult(runtime) else {
            return .failure(.wrongType(for: self, type: info.type,
                                       reason: "Isn't Result", .get()))
        }
        switch self {
        case .left(let err):
            return err.validate(runtime: runtime, type: result.err.type).map{_ in}
        case .right(let ok):
            return ok.validate(runtime: runtime, type: result.ok.type).map{_ in}
        }
    }
    
    
    public func asValue(runtime: Runtime, type info: NetworkType.Info) throws -> Value<NetworkType.Id> {
        guard let result = info.type.asResult(runtime) else {
            throw TypeError.wrongType(for: self, type: info.type,
                                      reason: "Isn't Result", .get())
        }
        switch self {
        case .left(let err):
            return try .variant(name: "Err",
                                values: [err.asValue(runtime: runtime,
                                                     type: result.err.type)], info.id)
        case .right(let ok):
            return try .variant(name: "Ok",
                                values: [ok.asValue(runtime: runtime,
                                                    type: result.ok.type)], info.id)
        }
    }
}

extension Either: VoidValueRepresentable where
    Left == VoidValueRepresentable, Right == VoidValueRepresentable
{
    public func asValue() -> Value<Void> {
        switch self {
        case .left(let err):
            return .variant(name: "Err", values: [err.asValue()])
        case .right(let ok):
            return .variant(name: "Ok", values: [ok.asValue()])
        }
    }
}
