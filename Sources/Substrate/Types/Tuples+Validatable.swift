//
//  Tuples+Validatable.swift
//  
//
//  Created by Yehor Popovych on 03/09/2023.
//

import Foundation
import Tuples

public protocol StaticValidatableTuple: StaticValidatableType, SomeTuple {
    static func validate(type: NetworkType.Info,
                         fields: inout [NetworkType.Info],
                         runtime: any Runtime) -> Result<Void, TypeError>
}

public extension SomeTuple0 {
    @inlinable
    static func validateTuple(runtime: Runtime,
                              type: NetworkType.Info) -> Result<Void, TypeError>
    {
        type.type.isEmpty(runtime) ?
            .success(()) : .failure(.wrongType(for: Self.self, got: type.type,
                                               reason: "Expected ()"))
    }
    
    @inlinable
    static func validate(type: NetworkType.Info,
                         fields: inout [NetworkType.Info],
                         runtime: any Runtime) -> Result<Void, TypeError>
    {
        fields.count == 0 ? .success(()) : .failure(.wrongValuesCount(for: Self.self,
                                                                      expected: 0,
                                                                      in: type.type))
    }
}

public extension ListTuple where DroppedLast: StaticValidatableTuple, Last: StaticValidatableType {
    static func validateTuple(runtime: Runtime,
                              type: NetworkType.Info) -> Result<Void, TypeError>
    {
        switch type.type.definition {
        case .array(count: let count, of: let id):
            guard count == self.count else {
                return .failure(.wrongValuesCount(for: Self.self,
                                                  expected: self.count, in: type.type))
            }
            guard let chType = runtime.resolve(type: id) else {
                return .failure(.typeNotFound(for: Self.self, id: id))
            }
            var fields = Array(repeating: chType.i(id), count: Int(count))
            return validate(type: type,
                            fields: &fields,
                            runtime: runtime)
        case .tuple(components: let ids):
            guard ids.count == self.count else {
                return .failure(.wrongValuesCount(for: Self.self,
                                                  expected: self.count, in: type.type))
            }
            return ids.resultMap { id in
                guard let chType = runtime.resolve(type: id) else {
                    return .failure(.typeNotFound(for: Self.self, id: id))
                }
                return .success(chType.i(id))
            }.flatMap { (fields: [NetworkType.Info]) in
                var fields = fields
                return validate(type: type, fields: &fields, runtime: runtime)
            }
        case .composite(fields: let fields):
            guard fields.count == self.count else {
                return .failure(.wrongValuesCount(for: Self.self,
                                                  expected: self.count, in: type.type))
            }
            return fields.resultMap { field in
                guard let chType = runtime.resolve(type: field.type) else {
                    return .failure(.typeNotFound(for: Self.self, id: field.type))
                }
                return .success(chType.i(field.type))
            }.flatMap { (fields: [NetworkType.Info]) in
                var fields = fields
                return validate(type: type, fields: &fields, runtime: runtime)
            }
        default:
            return .failure(.wrongType(for: Self.self,
                                       got: type.type,
                                       reason: "Isn't composite"))
        }
    }
    
    @inlinable
    static func validate(type: NetworkType.Info,
                         fields: inout [NetworkType.Info],
                         runtime: any Runtime) -> Result<Void, TypeError>
    {
        guard fields.count == self.count else {
            return .failure(.wrongValuesCount(for: Self.self,
                                              expected: self.count, in: type.type))
        }
        let ltype = fields.removeLast()
        return DroppedLast.validate(type: type, fields: &fields, runtime: runtime).flatMap {
            Last.validate(runtime: runtime, type: ltype)
        }
    }
}

extension Tuple0: StaticValidatableTuple {
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple1: StaticValidatableTuple, StaticValidatableType where T1: StaticValidatableType {
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError> {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple2: StaticValidatableTuple, StaticValidatableType where
    T1: StaticValidatableType, T2: StaticValidatableType
{
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple3: StaticValidatableTuple, StaticValidatableType where
    T1: StaticValidatableType, T2: StaticValidatableType, T3: StaticValidatableType
{
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple4: StaticValidatableTuple, StaticValidatableType where
    T1: StaticValidatableType, T2: StaticValidatableType, T3: StaticValidatableType, T4: StaticValidatableType
{
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple5: StaticValidatableTuple, StaticValidatableType where
    T1: StaticValidatableType, T2: StaticValidatableType, T3: StaticValidatableType, T4: StaticValidatableType,
    T5: StaticValidatableType
{
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple6: StaticValidatableTuple, StaticValidatableType where
    T1: StaticValidatableType, T2: StaticValidatableType, T3: StaticValidatableType, T4: StaticValidatableType,
    T5: StaticValidatableType, T6: StaticValidatableType
{
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple7: StaticValidatableTuple, StaticValidatableType where
    T1: StaticValidatableType, T2: StaticValidatableType, T3: StaticValidatableType, T4: StaticValidatableType,
    T5: StaticValidatableType, T6: StaticValidatableType, T7: StaticValidatableType
{
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple8: StaticValidatableTuple, StaticValidatableType where
    T1: StaticValidatableType, T2: StaticValidatableType, T3: StaticValidatableType, T4: StaticValidatableType,
    T5: StaticValidatableType, T6: StaticValidatableType, T7: StaticValidatableType, T8: StaticValidatableType
{
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple9: StaticValidatableTuple, StaticValidatableType where
    T1: StaticValidatableType, T2: StaticValidatableType, T3: StaticValidatableType, T4: StaticValidatableType,
    T5: StaticValidatableType, T6: StaticValidatableType, T7: StaticValidatableType, T8: StaticValidatableType,
    T9: StaticValidatableType
{
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple10: StaticValidatableTuple, StaticValidatableType where
    T1: StaticValidatableType, T2: StaticValidatableType, T3: StaticValidatableType, T4: StaticValidatableType,
    T5: StaticValidatableType, T6: StaticValidatableType, T7: StaticValidatableType, T8: StaticValidatableType,
    T9: StaticValidatableType, T10: StaticValidatableType
{
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple11: StaticValidatableTuple, StaticValidatableType where
    T1: StaticValidatableType, T2: StaticValidatableType, T3: StaticValidatableType, T4: StaticValidatableType,
    T5: StaticValidatableType, T6: StaticValidatableType, T7: StaticValidatableType, T8: StaticValidatableType,
    T9: StaticValidatableType, T10: StaticValidatableType, T11: StaticValidatableType
{
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple12: StaticValidatableTuple, StaticValidatableType where
    T1: StaticValidatableType, T2: StaticValidatableType, T3: StaticValidatableType, T4: StaticValidatableType,
    T5: StaticValidatableType, T6: StaticValidatableType, T7: StaticValidatableType, T8: StaticValidatableType,
    T9: StaticValidatableType, T10: StaticValidatableType, T11: StaticValidatableType, T12: StaticValidatableType
{
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple13: StaticValidatableTuple, StaticValidatableType where
    T1: StaticValidatableType, T2: StaticValidatableType, T3: StaticValidatableType, T4: StaticValidatableType,
    T5: StaticValidatableType, T6: StaticValidatableType, T7: StaticValidatableType, T8: StaticValidatableType,
    T9: StaticValidatableType, T10: StaticValidatableType, T11: StaticValidatableType, T12: StaticValidatableType,
    T13: StaticValidatableType
{
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple14: StaticValidatableTuple, StaticValidatableType where
    T1: StaticValidatableType, T2: StaticValidatableType, T3: StaticValidatableType, T4: StaticValidatableType,
    T5: StaticValidatableType, T6: StaticValidatableType, T7: StaticValidatableType, T8: StaticValidatableType,
    T9: StaticValidatableType, T10: StaticValidatableType, T11: StaticValidatableType, T12: StaticValidatableType,
    T13: StaticValidatableType, T14: StaticValidatableType
{
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple15: StaticValidatableTuple, StaticValidatableType where
    T1: StaticValidatableType, T2: StaticValidatableType, T3: StaticValidatableType, T4: StaticValidatableType,
    T5: StaticValidatableType, T6: StaticValidatableType, T7: StaticValidatableType, T8: StaticValidatableType,
    T9: StaticValidatableType, T10: StaticValidatableType, T11: StaticValidatableType, T12: StaticValidatableType,
    T13: StaticValidatableType, T14: StaticValidatableType, T15: StaticValidatableType
{
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}
