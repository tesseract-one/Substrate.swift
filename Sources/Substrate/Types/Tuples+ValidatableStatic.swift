//
//  Tuples+ValidatableStatic.swift
//  
//
//  Created by Yehor Popovych on 03/09/2023.
//

import Foundation
import Tuples

public protocol ValidatableTupleStatic: ValidatableTypeStatic, SomeTuple {
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
            .success(()) : .failure(.wrongType(for: Self.self, type: type.type,
                                               reason: "Expected ()", .get()))
    }
    
    @inlinable
    static func validate(type: NetworkType.Info,
                         fields: inout [NetworkType.Info],
                         runtime: any Runtime) -> Result<Void, TypeError>
    {
        fields.count == 0 ? .success(()) : .failure(.wrongValuesCount(for: Self.self,
                                                                      expected: 0,
                                                                      type: type.type,
                                                                      .get()))
    }
}

public extension ListTuple where DroppedLast: ValidatableTupleStatic, Last: ValidatableTypeStatic {
    static func validateTuple(runtime: Runtime,
                              type: NetworkType.Info) -> Result<Void, TypeError>
    {
        switch type.type.definition {
        case .array(count: let count, of: let id):
            guard count == self.count else {
                return .failure(.wrongValuesCount(for: Self.self,
                                                  expected: self.count,
                                                  type: type.type, .get()))
            }
            guard let chType = runtime.resolve(type: id) else {
                return .failure(.typeNotFound(for: Self.self, id: id, .get()))
            }
            var fields = Array(repeating: chType.i(id), count: Int(count))
            return validate(type: type,
                            fields: &fields,
                            runtime: runtime)
        case .tuple(components: let ids):
            guard ids.count == self.count else {
                return .failure(.wrongValuesCount(for: Self.self,
                                                  expected: self.count,
                                                  type: type.type, .get()))
            }
            return ids.resultMap { id in
                guard let chType = runtime.resolve(type: id) else {
                    return .failure(.typeNotFound(for: Self.self, id: id, .get()))
                }
                return .success(chType.i(id))
            }.flatMap { (fields: [NetworkType.Info]) in
                var fields = fields
                return validate(type: type, fields: &fields, runtime: runtime)
            }
        case .composite(fields: let fields):
            guard fields.count == self.count else {
                return .failure(.wrongValuesCount(for: Self.self,
                                                  expected: self.count,
                                                  type: type.type, .get()))
            }
            return fields.resultMap { field in
                guard let chType = runtime.resolve(type: field.type) else {
                    return .failure(.typeNotFound(for: Self.self, id: field.type, .get()))
                }
                return .success(chType.i(field.type))
            }.flatMap { (fields: [NetworkType.Info]) in
                var fields = fields
                return validate(type: type, fields: &fields, runtime: runtime)
            }
        default:
            return .failure(.wrongType(for: Self.self,
                                       type: type.type,
                                       reason: "Isn't composite", .get()))
        }
    }
    
    @inlinable
    static func validate(type: NetworkType.Info,
                         fields: inout [NetworkType.Info],
                         runtime: any Runtime) -> Result<Void, TypeError>
    {
        guard fields.count == self.count else {
            return .failure(.wrongValuesCount(for: Self.self,
                                              expected: self.count,
                                              type: type.type, .get()))
        }
        let ltype = fields.removeLast()
        return DroppedLast.validate(type: type, fields: &fields, runtime: runtime).flatMap {
            Last.validate(runtime: runtime, type: ltype)
        }
    }
}

extension Tuple0: ValidatableTupleStatic {
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple1: ValidatableTupleStatic, ValidatableTypeStatic where T1: ValidatableTypeStatic {
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError> {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple2: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic
{
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple3: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic, T3: ValidatableTypeStatic
{
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple4: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic, T3: ValidatableTypeStatic, T4: ValidatableTypeStatic
{
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple5: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic, T3: ValidatableTypeStatic, T4: ValidatableTypeStatic,
    T5: ValidatableTypeStatic
{
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple6: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic, T3: ValidatableTypeStatic, T4: ValidatableTypeStatic,
    T5: ValidatableTypeStatic, T6: ValidatableTypeStatic
{
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple7: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic, T3: ValidatableTypeStatic, T4: ValidatableTypeStatic,
    T5: ValidatableTypeStatic, T6: ValidatableTypeStatic, T7: ValidatableTypeStatic
{
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple8: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic, T3: ValidatableTypeStatic, T4: ValidatableTypeStatic,
    T5: ValidatableTypeStatic, T6: ValidatableTypeStatic, T7: ValidatableTypeStatic, T8: ValidatableTypeStatic
{
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple9: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic, T3: ValidatableTypeStatic, T4: ValidatableTypeStatic,
    T5: ValidatableTypeStatic, T6: ValidatableTypeStatic, T7: ValidatableTypeStatic, T8: ValidatableTypeStatic,
    T9: ValidatableTypeStatic
{
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple10: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic, T3: ValidatableTypeStatic, T4: ValidatableTypeStatic,
    T5: ValidatableTypeStatic, T6: ValidatableTypeStatic, T7: ValidatableTypeStatic, T8: ValidatableTypeStatic,
    T9: ValidatableTypeStatic, T10: ValidatableTypeStatic
{
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple11: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic, T3: ValidatableTypeStatic, T4: ValidatableTypeStatic,
    T5: ValidatableTypeStatic, T6: ValidatableTypeStatic, T7: ValidatableTypeStatic, T8: ValidatableTypeStatic,
    T9: ValidatableTypeStatic, T10: ValidatableTypeStatic, T11: ValidatableTypeStatic
{
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple12: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic, T3: ValidatableTypeStatic, T4: ValidatableTypeStatic,
    T5: ValidatableTypeStatic, T6: ValidatableTypeStatic, T7: ValidatableTypeStatic, T8: ValidatableTypeStatic,
    T9: ValidatableTypeStatic, T10: ValidatableTypeStatic, T11: ValidatableTypeStatic, T12: ValidatableTypeStatic
{
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple13: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic, T3: ValidatableTypeStatic, T4: ValidatableTypeStatic,
    T5: ValidatableTypeStatic, T6: ValidatableTypeStatic, T7: ValidatableTypeStatic, T8: ValidatableTypeStatic,
    T9: ValidatableTypeStatic, T10: ValidatableTypeStatic, T11: ValidatableTypeStatic, T12: ValidatableTypeStatic,
    T13: ValidatableTypeStatic
{
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple14: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic, T3: ValidatableTypeStatic, T4: ValidatableTypeStatic,
    T5: ValidatableTypeStatic, T6: ValidatableTypeStatic, T7: ValidatableTypeStatic, T8: ValidatableTypeStatic,
    T9: ValidatableTypeStatic, T10: ValidatableTypeStatic, T11: ValidatableTypeStatic, T12: ValidatableTypeStatic,
    T13: ValidatableTypeStatic, T14: ValidatableTypeStatic
{
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}

extension Tuple15: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic, T3: ValidatableTypeStatic, T4: ValidatableTypeStatic,
    T5: ValidatableTypeStatic, T6: ValidatableTypeStatic, T7: ValidatableTypeStatic, T8: ValidatableTypeStatic,
    T9: ValidatableTypeStatic, T10: ValidatableTypeStatic, T11: ValidatableTypeStatic, T12: ValidatableTypeStatic,
    T13: ValidatableTypeStatic, T14: ValidatableTypeStatic, T15: ValidatableTypeStatic
{
    @inlinable
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        validateTuple(runtime: runtime, type: info)
    }
}
