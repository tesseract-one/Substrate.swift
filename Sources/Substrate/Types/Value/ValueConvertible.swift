//
//  ValueConvertible.swift
//  
//
//  Created by Yehor Popovych on 17.01.2023.
//

import Foundation
import ScaleCodec

//public protocol ValueInitializable {
//    init<C>(value: Value<C>) throws
//}

public protocol ValueRepresentable {
    func asValue(runtime: any Runtime, type: RuntimeType.Id) throws -> Value<RuntimeType.Id>
}

public protocol VoidValueRepresentable {
    func asValue() -> Value<Void>
}

//public typealias ValueConvertible = ValueInitializable & ValueRepresentable

//public protocol ValueArrayInitializable {
//    init<C>(values: [Value<C>]) throws
//}

//public protocol ValueArrayRepresentable {
//    func asValueArray(runtime: any Runtime, id: @escaping RuntimeType.LazyId) throws -> Value<RuntimeType.Id>
//}
//
//public protocol ValueMapInitializable {
//    init<C>(values: [String: Value<C>]) throws
//}
//
//public protocol ValueMapRepresentable {
//    func asValueMap() throws -> [String: Value<Void>]
//}

//public extension ValueArrayInitializable {
//    init<C>(value: Value<C>) throws {
//        switch value.value {
//        case .sequence(let values): try self.init(values: values)
//        default:
//            throw ValueInitializableError.wrongValueType(got: value.value,
//                                                         for: String(describing: Self.self))
//        }
//    }
//}
//
//public extension ValueArrayRepresentable {
//    func asValue() throws -> Value<Void> { try .sequence(asValueArray()) }
//}
//
//public extension ValueMapInitializable {
//    init<C>(value: Value<C>) throws {
//        switch value.value {
//        case .map(let fields): try self.init(values: fields)
//        default:
//            throw ValueInitializableError.wrongValueType(got: value.value,
//                                                         for: String(describing: Self.self))
//        }
//    }
//}
//
//public extension ValueMapRepresentable {
//    func asValue() throws -> Value<Void> { try .map(asValueMap()) }
//}

//public enum ValueInitializableError<C>: Error {
//    case wrongValueType(got: Value<C>.Def, for: String)
//    case wrongValuesCount(in: Value<C>.Def, expected: Int, for: String)
//    case unknownVariant(name: String, in: Value<C>.Def, for: String)
//    case integerOverflow(got: Int512, min: Int512, max: Int512)
//}

public enum ValueRepresentableError: Error {
    case typeNotFound(RuntimeType.Id)
    case wrongType(got: RuntimeType, for: String)
    case wrongValuesCount(in: RuntimeType, expected: Int, for: String)
    case nonVariant(map: [String: ValueRepresentable])
    case variantNotFound(name: String, in: RuntimeType)
    case keyNotFound(key: String, in: [String: ValueRepresentable])
    case typeIdMismatch(got: RuntimeType.Id, has: RuntimeType.Id)
}

public extension FixedWidthInteger {
//    init<C>(value: Value<C>) throws {
//        switch value.value {
//        case .primitive(.u256(let uint)):
//            guard uint <= Self.max else {
//                throw ValueInitializableError<C>.integerOverflow(got: Int512(uint),
//                                                                 min: Int512(Self.min),
//                                                                 max: Int512(Self.max))
//            }
//            self.init(uint)
//        case .primitive(.i256(let int)):
//            guard int <= Self.max && int >= Self.min else {
//                throw ValueInitializableError<C>.integerOverflow(got: Int512(int),
//                                                                 min: Int512(Self.min),
//                                                                 max: Int512(Self.max))
//            }
//            self.init(int)
//        default:
//            throw ValueInitializableError<C>.wrongValueType(got: value.value,
//                                                            for: String(describing: Self.self))
//        }
//    }
    func asValue() -> Value<Void> {
        Self.isSigned ?  .i256(Int256(self)) : .u256(UInt256(self))
    }
    
    func asValue(runtime: any Runtime, type: RuntimeType.Id) throws -> Value<RuntimeType.Id> {
        guard let info = runtime.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        guard let primitive = info.asPrimitive(metadata: runtime.metadata), primitive.isAnyInt else {
            throw ValueRepresentableError.wrongType(got: info, for: String(describing: Self.self))
        }
        return Self.isSigned ?  .i256(Int256(self), type) : .u256(UInt256(self), type)
    }
}

extension UInt8: ValueRepresentable, VoidValueRepresentable {}
extension UInt16: ValueRepresentable, VoidValueRepresentable {}
extension UInt32: ValueRepresentable, VoidValueRepresentable {}
extension UInt64: ValueRepresentable, VoidValueRepresentable {}
extension UInt: ValueRepresentable, VoidValueRepresentable {}
extension DoubleWidth: ValueRepresentable, VoidValueRepresentable {}
extension Int8: ValueRepresentable, VoidValueRepresentable {}
extension Int16: ValueRepresentable, VoidValueRepresentable {}
extension Int32: ValueRepresentable, VoidValueRepresentable {}
extension Int64: ValueRepresentable, VoidValueRepresentable {}
extension Int: ValueRepresentable, VoidValueRepresentable {}

//extension Value: ValueInitializable where C == Void {
//    public init<C2>(value: Value<C2>) throws {
//        self = value.mapContext(with: { _ in })
//    }
//}

extension Value: ValueRepresentable, VoidValueRepresentable {
    public func asValue() -> Value<Void> { mapContext{_ in} }
    
    public func asValue(runtime: any Runtime, type: RuntimeType.Id) throws -> Value<RuntimeType.Id> {
        if let sself = self as? Value<RuntimeType.Id> {
            guard sself.context == type else {
                throw ValueRepresentableError.typeIdMismatch(got: type, has: sself.context)
            }
            return sself
        }
        return mapContext{_ in type}
    }
}

extension Bool: ValueRepresentable, VoidValueRepresentable {
//    public init<C>(value: Value<C>) throws {
//        guard let bool = value.bool else {
//            throw ValueInitializableError.wrongValueType(got: value.value,
//                                                         for: "Bool")
//        }
//        self = bool
//    }
//
    public func asValue() -> Value<Void> { .bool(self) }
    
    public func asValue(runtime: any Runtime, type: RuntimeType.Id) throws -> Value<RuntimeType.Id> {
        guard let info = runtime.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        guard let primitive = info.asPrimitive(metadata: runtime.metadata), primitive.isBool else {
            throw ValueRepresentableError.wrongType(got: info, for: String(describing: Self.self))
        }
        return .bool(self, type)
    }
}

extension String: ValueRepresentable, VoidValueRepresentable {
//    public init<C>(value: Value<C>) throws {
//        guard let string = value.string else {
//            throw ValueInitializableError.wrongValueType(got: value.value,
//                                                         for: "String")
//        }
//        self = string
//    }
    public func asValue() -> Value<Void> { .string(self) }
    
    public func asValue(runtime: any Runtime, type: RuntimeType.Id) throws -> Value<RuntimeType.Id> {
        guard let info = runtime.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        guard let primitive = info.asPrimitive(metadata: runtime.metadata), primitive.isString else {
            throw ValueRepresentableError.wrongType(got: info, for: String(describing: Self.self))
        }
        return .string(self, type)
    }
}

extension Data: ValueRepresentable, VoidValueRepresentable {
//    public init<C>(value: Value<C>) throws {
//        guard let data = value.bytes else {
//            throw ValueInitializableError.wrongValueType(got: value.value,
//                                                         for: "Data")
//        }
//        self = data
//    }
    public func asValue() -> Value<Void> { .bytes(self) }
    
    public func asValue(runtime: any Runtime, type: RuntimeType.Id) throws -> Value<RuntimeType.Id> {
        guard let info = runtime.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        guard let count = info.asBytes(metadata: runtime.metadata) else {
            throw ValueRepresentableError.wrongType(got: info, for: String(describing: Self.self))
        }
        guard count == 0 || self.count == count else {
            throw ValueRepresentableError.wrongValuesCount(in: info, expected: self.count,
                                                           for: String(describing: Self.self))
        }
        return .bytes(self, type)
    }
}

extension Character: ValueRepresentable, VoidValueRepresentable {
//    public init<C>(value: Value<C>) throws {
//        guard let char = value.char else {
//            throw ValueInitializableError.wrongValueType(got: value.value,
//                                                         for: "Character")
//        }
//        self = char
//    }
    public func asValue() -> Value<Void> { .char(self) }
    
    public func asValue(runtime: any Runtime, type: RuntimeType.Id) throws -> Value<RuntimeType.Id> {
        guard let info = runtime.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        guard let primitive = info.asPrimitive(metadata: runtime.metadata), primitive.isChar else {
            throw ValueRepresentableError.wrongType(got: info, for: String(describing: Self.self))
        }
        return .char(self, type)
    }
}

public extension Collection where Element == ValueRepresentable {
    func asValue(runtime: any Runtime, type: RuntimeType.Id) throws -> Value<RuntimeType.Id> {
        guard let info = runtime.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        let flat = info.flatten(metadata: runtime.metadata)
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
                          type: RuntimeType.Info,
                          types: [RuntimeType.Id]) throws -> [Value<RuntimeType.Id>] {
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
    public func asValue(runtime: Runtime, type: RuntimeType.Id) throws -> Substrate.Value<RuntimeType.Id> {
        guard let info = runtime.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        let flat = info.flatten(metadata: runtime.metadata)
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
        type: RuntimeType.Info,
        types: [String: RuntimeType.Id]) throws -> [String: Substrate.Value<RuntimeType.Id>]
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
    public func asValue(runtime: Runtime, type: RuntimeType.Id) throws -> Value<RuntimeType.Id> {
        guard let info = runtime.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        guard let field = info.asOptional(metadata: runtime.metadata) else {
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
    public func asValue(runtime: Runtime, type: RuntimeType.Id) throws -> Value<RuntimeType.Id> {
        guard let info = runtime.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        guard let result = info.asResult(metadata: runtime.metadata) else {
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
