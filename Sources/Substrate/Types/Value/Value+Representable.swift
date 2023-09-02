//
//  Value+Representable.swift
//  
//
//  Created by Yehor Popovych on 17.01.2023.
//

import Foundation
import ScaleCodec
import Numberick

public enum ValueRepresentableError: Error {
    case typeNotFound(NetworkType.Id)
    case wrongType(got: NetworkType, for: String)
    case wrongValuesCount(in: NetworkType, expected: Int, for: String)
    case nonVariant(map: [String: ValueRepresentable])
    case variantNotFound(name: String, in: NetworkType)
    case fieldNotFound(name: String, in: NetworkType)
    case keyNotFound(key: String, in: [String: ValueRepresentable])
    case runtimeTypeLookupFailed(name: String, reason: Error)
    case typeIdMismatch(got: NetworkType.Id, has: NetworkType.Id)
    
    public init(_ error: DynamicValidationError) {
        switch error {
        case .typeIdMismatch(got: let gid, has: let hid):
            self = .typeIdMismatch(got: gid, has: hid)
        case .typeNotFound(let tid):
            self = .typeNotFound(tid)
        case .variantNotFound(name: let n, in: let t):
            self = .variantNotFound(name: n, in: t)
        case .wrongType(got: let t, for: let n):
            self = .wrongType(got: t, for: n)
        case .wrongValuesCount(in: let t, expected: let c, for: let n):
            self = .wrongValuesCount(in: t, expected: c, for: n)
        case .fieldNotFound(name: let n, in: let t):
            self = .fieldNotFound(name: n, in: t)
        case .runtimeTypeLookupFailed(name: let n, reason: let e):
            self = .runtimeTypeLookupFailed(name: n, reason: e)
        }
    }
}

public extension Result where Failure == DynamicValidationError {
    @inlinable func getValueError() throws -> Success {
        try mapError { ValueRepresentableError($0) }.get()
    }
}

public extension FixedWidthInteger {
    func asValue() -> Value<Void> {
        Self.isSigned ?  .int(Int256(self)) : .uint(UInt256(self))
    }
    
    func asValue(runtime: any Runtime, type: NetworkType.Id) throws -> Value<NetworkType.Id> {
        guard let info = runtime.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        guard let primitive = info.asPrimitive(runtime), primitive.isAnyInt != nil else {
            throw ValueRepresentableError.wrongType(got: info, for: String(describing: Self.self))
        }
        return Self.isSigned ?  .int(Int256(self), type) : .uint(UInt256(self), type)
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
    
    public func asValue(runtime: any Runtime, type: NetworkType.Id) throws -> Value<NetworkType.Id> {
        if let sself = self as? Value<NetworkType.Id> {
            guard sself.context == type else {
                throw ValueRepresentableError.typeIdMismatch(got: type, has: sself.context)
            }
            return sself
        }
        return mapContext{_ in type}
    }
}

extension Bool: ValueRepresentable, VoidValueRepresentable {
    public func asValue() -> Value<Void> { .bool(self) }
    
    public func asValue(runtime: any Runtime, type: NetworkType.Id) throws -> Value<NetworkType.Id> {
        try Self.validate(runtime: runtime, type: type).getValueError()
        return .bool(self, type)
    }
}

extension String: ValueRepresentable, VoidValueRepresentable {
    public func asValue() -> Value<Void> { .string(self) }
    
    public func asValue(runtime: any Runtime, type: NetworkType.Id) throws -> Value<NetworkType.Id> {
        try Self.validate(runtime: runtime, type: type).getValueError()
        return .string(self, type)
    }
}

extension Data: ValueRepresentable, VoidValueRepresentable {
    public func asValue() -> Value<Void> { .bytes(self) }
    
    public func asValue(runtime: any Runtime, type: NetworkType.Id) throws -> Value<NetworkType.Id> {
        guard let info = runtime.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        guard let count = info.asBytes(runtime) else {
            throw ValueRepresentableError.wrongType(got: info, for: String(describing: Self.self))
        }
        guard count == 0 || self.count == count else {
            throw ValueRepresentableError.wrongValuesCount(
                in: info, expected: self.count, for: String(describing: Self.self)
            )
        }
        return .bytes(self, type)
    }
}

extension Compact: ValueRepresentable, VoidValueRepresentable {
    public func asValue() -> Value<Void> { .uint(UInt256(value.uint)) }
    
    public func asValue(runtime: any Runtime, type: NetworkType.Id) throws -> Value<NetworkType.Id> {
        guard let info = runtime.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        guard info.asCompact(runtime) != nil else {
            throw ValueRepresentableError.wrongType(got: info, for: String(describing: Self.self))
        }
        return .uint(UInt256(value.uint), type)
    }
}

extension Character: ValueRepresentable, VoidValueRepresentable {
    public func asValue() -> Value<Void> { .char(self) }
    
    public func asValue(runtime: any Runtime, type: NetworkType.Id) throws -> Value<NetworkType.Id> {
        guard let info = runtime.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        guard let primitive = info.asPrimitive(runtime), primitive.isChar else {
            throw ValueRepresentableError.wrongType(got: info, for: String(describing: Self.self))
        }
        return .char(self, type)
    }
}

public extension Collection where Element == ValueRepresentable {
    func asValue(runtime: any Runtime, type: NetworkType.Id) throws -> Value<NetworkType.Id> {
        guard let info = runtime.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        let flat = info.flatten(runtime)
        switch flat.definition {
        case .array(count: let count, of: let eType):
            guard count == self.count else {
                throw ValueRepresentableError.wrongValuesCount(in: info,
                                                               expected: self.count,
                                                               for: String(describing: Self.self))
            }
            fallthrough
        case .sequence(of: let eType):
            let mapped = try map{ try $0.asValue(runtime: runtime, type: eType) }
            return .sequence(mapped, type)
        case .composite(fields: let fields):
            let arr = try asCompositeValue(runtime: runtime,
                                           type: .init(id: type, type: info),
                                           types: fields.map { $0.type })
            return .sequence(arr, type)
        case .tuple(components: let ids):
            let arr = try asCompositeValue(runtime: runtime,
                                           type: .init(id: type, type: info),
                                           types: ids)
            return .sequence(arr, type)
        default:
            throw ValueRepresentableError.wrongType(got: info, for: String(describing: Self.self))
        }
    }
    
    func asCompositeValue(runtime: any Runtime,
                          type: NetworkType.Info,
                          types: [NetworkType.Id]) throws -> [Value<NetworkType.Id>] {
        guard types.count == count else {
            throw ValueRepresentableError.wrongValuesCount(in: type.type,
                                                           expected: count,
                                                           for: String(describing: Self.self))
        }
        return try zip(self, types).map { try $0.asValue(runtime: runtime, type: $1) }
    }
}

public extension Sequence where Element == VoidValueRepresentable {
    func asValue() -> Value<Void> {.sequence(self)}
}

extension Array: ValueRepresentable where Element == ValueRepresentable {}
extension Array: VoidValueRepresentable where Element == VoidValueRepresentable {}

extension Dictionary: ValueRepresentable where Key == String, Value == ValueRepresentable {
    public func asValue(runtime: Runtime, type: NetworkType.Id) throws -> Substrate.Value<NetworkType.Id> {
        guard let info = runtime.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        let flat = info.flatten(runtime)
        switch flat.definition {
        case .composite(fields: let fields):
            let types = try fields.map { field in
                guard let key = field.name else {
                    throw ValueRepresentableError.wrongType(got: info,
                                                            for: String(describing: Self.self))
                }
                return (key, field.type)
            }
            let map = try asCompositeValue(runtime: runtime,
                                           type: .init(id: type, type: info),
                                           types: Dictionary<_,_>(uniqueKeysWithValues: types))
            return .map(map, type)
        case .variant(variants: let variants):
            guard count == 1 else {
                throw ValueRepresentableError.nonVariant(map: self)
            }
            guard let variant = variants.first(where: { $0.name == first!.key }) else {
                throw ValueRepresentableError.variantNotFound(name: first!.key, in: info)
            }
            if variant.fields.count == 1 {
                let val = try first!.value.asValue(runtime: runtime,
                                                   type: variant.fields.first!.type)
                if let name = variant.fields.first?.name {
                    return .variant(name: variant.name, fields: [name: val], type)
                } else {
                    return .variant(name: variant.name, values: [val], type)
                }
            }
            switch first!.value {
            case let arr as Array<ValueRepresentable>:
                let seq = try arr.asCompositeValue(runtime: runtime,
                                                   type: .init(id: type, type: info),
                                                   types: variant.fields.map{$0.type})
                return .variant(name: variant.name, values: seq, type)
            case let map as Dictionary<String, ValueRepresentable>:
                let types = try variant.fields.map { field in
                    guard let key = field.name else {
                        throw ValueRepresentableError.wrongType(got: info,
                                                                for: String(describing: Self.self))
                    }
                    return (key, field.type)
                }
                let map = try map.asCompositeValue(runtime: runtime,
                                                   type: .init(id: type, type: info),
                                                   types: Dictionary<_,_>(uniqueKeysWithValues: types))
                return .variant(name: variant.name, fields: map, type)
            default: throw ValueRepresentableError.wrongType(got: info,
                                                             for: String(describing: Self.self))
            }
        default:
            throw ValueRepresentableError.wrongType(got: info, for: String(describing: Self.self))
        }
    }
    
    func asCompositeValue(
        runtime: any Runtime,
        type: NetworkType.Info,
        types: [String: NetworkType.Id]) throws -> [String: Substrate.Value<NetworkType.Id>]
    {
        guard types.count == count else {
            throw ValueRepresentableError.wrongValuesCount(in: type.type,
                                                           expected: count,
                                                           for: String(describing: Self.self))
        }
        let pairs = try types.map { field in
            guard let value = self[field.key] else {
                throw ValueRepresentableError.keyNotFound(key: field.key, in: self)
            }
            return try (field.key, value.asValue(runtime: runtime, type: field.value))
        }
        return Dictionary<_,_>(uniqueKeysWithValues: pairs)
    }
}

extension Dictionary: VoidValueRepresentable where Key: StringProtocol, Value == VoidValueRepresentable {
    public func asValue() -> Substrate.Value<Void> {
        .map(map { (String($0.key), $0.value.asValue()) })
    }
}

extension Optional: ValueRepresentable where Wrapped == ValueRepresentable {
    public func asValue(runtime: Runtime, type: NetworkType.Id) throws -> Value<NetworkType.Id> {
        guard let info = runtime.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        guard let field = info.asOptional(runtime) else {
            throw ValueRepresentableError.wrongType(got: info, for: String(describing: Self.self))
        }
        switch self {
        case .some(let val):
            return try .variant(name: "Some",
                                values: [val.asValue(runtime: runtime, type: field.type)], type)
        case .none: return .variant(name: "None", values: [], type)
        }
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

extension Either: ValueRepresentable where Left == ValueRepresentable, Right == ValueRepresentable {
    public func asValue(runtime: Runtime, type: NetworkType.Id) throws -> Value<NetworkType.Id> {
        guard let info = runtime.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        guard let result = info.asResult(runtime) else {
            throw ValueRepresentableError.wrongType(got: info, for: String(describing: Self.self))
        }
        switch self {
        case .left(let err):
            return try .variant(name: "Err",
                                values: [err.asValue(runtime: runtime, type: result.err.type)], type)
        case .right(let ok):
            return try .variant(name: "Ok",
                                values: [ok.asValue(runtime: runtime, type: result.ok.type)], type)
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
