//
//  Tuples+ValidatableStatic.swift
//  
//
//  Created by Yehor Popovych on 03/09/2023.
//

import Foundation
import Tuples

public protocol ValidatableTupleStatic: ValidatableTypeStatic, SomeTuple {
    static func validate(type: TypeDefinition,
                         fields: inout [TypeDefinition.Field]) -> Result<Void, TypeError>
}

public extension SomeTuple0 {
    @inlinable
    static func validateTuple(type: TypeDefinition) -> Result<Void, TypeError>
    {
        type.isEmpty() ?
            .success(()) : .failure(.wrongType(for: Self.self, type: type,
                                               reason: "Expected empty", .get()))
    }
    
    @inlinable
    static func validate(type: TypeDefinition,
                         fields: inout [TypeDefinition.Field]) -> Result<Void, TypeError>
    {
        fields.count == 0 ? .success(()) : .failure(.wrongValuesCount(for: Self.self,
                                                                      expected: 0,
                                                                      type: type,
                                                                      .get()))
    }
}

public extension ListTuple where DroppedLast: ValidatableTupleStatic, Last: ValidatableTypeStatic {
    static func validateTuple(type: TypeDefinition) -> Result<Void, TypeError>
    {
        switch type.definition {
        case .array(count: let count, of: let chType):
            guard count == self.count else {
                return .failure(.wrongValuesCount(for: Self.self,
                                                  expected: self.count,
                                                  type: type, .get()))
            }
            var fields = Array(repeating: TypeDefinition.Field.v(chType), count: Int(count))
            return validate(type: type, fields: &fields)
        case .composite(fields: var fields):
            guard fields.count == self.count else {
                return .failure(.wrongValuesCount(for: Self.self,
                                                  expected: self.count,
                                                  type: type, .get()))
            }
            return validate(type: type, fields: &fields)
        default:
            return .failure(.wrongType(for: Self.self,
                                       type: type,
                                       reason: "Isn't composite", .get()))
        }
    }
    
    @inlinable
    static func validate(type: TypeDefinition,
                         fields: inout [TypeDefinition.Field]) -> Result<Void, TypeError>
    {
        guard fields.count == self.count else {
            return .failure(.wrongValuesCount(for: Self.self,
                                              expected: self.count,
                                              type: type, .get()))
        }
        let ltype = fields.removeLast()
        return DroppedLast.validate(type: type, fields: &fields).flatMap {
            Last.validate(type: ltype.type)
        }
    }
}

extension Tuple0: ValidatableTupleStatic {
    public static func validate(type: TypeDefinition) -> Result<Void, TypeError>
    {
        validateTuple(type: type)
    }
}

extension Tuple1: ValidatableTupleStatic, ValidatableTypeStatic where T1: ValidatableTypeStatic {
    @inlinable
    public static func validate(type: TypeDefinition) -> Result<Void, TypeError> {
        validateTuple(type: type)
    }
}

extension Tuple2: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic
{
    @inlinable
    public static func validate(type: TypeDefinition) -> Result<Void, TypeError>
    {
        validateTuple(type: type)
    }
}

extension Tuple3: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic, T3: ValidatableTypeStatic
{
    @inlinable
    public static func validate(type: TypeDefinition) -> Result<Void, TypeError>
    {
        validateTuple(type: type)
    }
}

extension Tuple4: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic, T3: ValidatableTypeStatic, T4: ValidatableTypeStatic
{
    @inlinable
    public static func validate(type: TypeDefinition) -> Result<Void, TypeError>
    {
        validateTuple(type: type)
    }
}

extension Tuple5: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic, T3: ValidatableTypeStatic, T4: ValidatableTypeStatic,
    T5: ValidatableTypeStatic
{
    @inlinable
    public static func validate(type: TypeDefinition) -> Result<Void, TypeError>
    {
        validateTuple(type: type)
    }
}

extension Tuple6: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic, T3: ValidatableTypeStatic, T4: ValidatableTypeStatic,
    T5: ValidatableTypeStatic, T6: ValidatableTypeStatic
{
    public static func validate(type: TypeDefinition) -> Result<Void, TypeError>
    {
        validateTuple(type: type)
    }
}

extension Tuple7: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic, T3: ValidatableTypeStatic, T4: ValidatableTypeStatic,
    T5: ValidatableTypeStatic, T6: ValidatableTypeStatic, T7: ValidatableTypeStatic
{
    @inlinable
    public static func validate(type: TypeDefinition) -> Result<Void, TypeError>
    {
        validateTuple(type: type)
    }
}

extension Tuple8: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic, T3: ValidatableTypeStatic, T4: ValidatableTypeStatic,
    T5: ValidatableTypeStatic, T6: ValidatableTypeStatic, T7: ValidatableTypeStatic, T8: ValidatableTypeStatic
{
    @inlinable
    public static func validate(type: TypeDefinition) -> Result<Void, TypeError>
    {
        validateTuple(type: type)
    }
}

extension Tuple9: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic, T3: ValidatableTypeStatic, T4: ValidatableTypeStatic,
    T5: ValidatableTypeStatic, T6: ValidatableTypeStatic, T7: ValidatableTypeStatic, T8: ValidatableTypeStatic,
    T9: ValidatableTypeStatic
{
    @inlinable
    public static func validate(type: TypeDefinition) -> Result<Void, TypeError>
    {
        validateTuple(type: type)
    }
}

extension Tuple10: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic, T3: ValidatableTypeStatic, T4: ValidatableTypeStatic,
    T5: ValidatableTypeStatic, T6: ValidatableTypeStatic, T7: ValidatableTypeStatic, T8: ValidatableTypeStatic,
    T9: ValidatableTypeStatic, T10: ValidatableTypeStatic
{
    @inlinable
    public static func validate(type: TypeDefinition) -> Result<Void, TypeError>
    {
        validateTuple(type: type)
    }
}

extension Tuple11: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic, T3: ValidatableTypeStatic, T4: ValidatableTypeStatic,
    T5: ValidatableTypeStatic, T6: ValidatableTypeStatic, T7: ValidatableTypeStatic, T8: ValidatableTypeStatic,
    T9: ValidatableTypeStatic, T10: ValidatableTypeStatic, T11: ValidatableTypeStatic
{
    @inlinable
    public static func validate(type: TypeDefinition) -> Result<Void, TypeError>
    {
        validateTuple(type: type)
    }
}

extension Tuple12: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic, T3: ValidatableTypeStatic, T4: ValidatableTypeStatic,
    T5: ValidatableTypeStatic, T6: ValidatableTypeStatic, T7: ValidatableTypeStatic, T8: ValidatableTypeStatic,
    T9: ValidatableTypeStatic, T10: ValidatableTypeStatic, T11: ValidatableTypeStatic, T12: ValidatableTypeStatic
{
    @inlinable
    public static func validate(type: TypeDefinition) -> Result<Void, TypeError>
    {
        validateTuple(type: type)
    }
}

extension Tuple13: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic, T3: ValidatableTypeStatic, T4: ValidatableTypeStatic,
    T5: ValidatableTypeStatic, T6: ValidatableTypeStatic, T7: ValidatableTypeStatic, T8: ValidatableTypeStatic,
    T9: ValidatableTypeStatic, T10: ValidatableTypeStatic, T11: ValidatableTypeStatic, T12: ValidatableTypeStatic,
    T13: ValidatableTypeStatic
{
    @inlinable
    public static func validate(type: TypeDefinition) -> Result<Void, TypeError>
    {
        validateTuple(type: type)
    }
}

extension Tuple14: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic, T3: ValidatableTypeStatic, T4: ValidatableTypeStatic,
    T5: ValidatableTypeStatic, T6: ValidatableTypeStatic, T7: ValidatableTypeStatic, T8: ValidatableTypeStatic,
    T9: ValidatableTypeStatic, T10: ValidatableTypeStatic, T11: ValidatableTypeStatic, T12: ValidatableTypeStatic,
    T13: ValidatableTypeStatic, T14: ValidatableTypeStatic
{
    @inlinable
    public static func validate(type: TypeDefinition) -> Result<Void, TypeError>
    {
        validateTuple(type: type)
    }
}

extension Tuple15: ValidatableTupleStatic, ValidatableTypeStatic where
    T1: ValidatableTypeStatic, T2: ValidatableTypeStatic, T3: ValidatableTypeStatic, T4: ValidatableTypeStatic,
    T5: ValidatableTypeStatic, T6: ValidatableTypeStatic, T7: ValidatableTypeStatic, T8: ValidatableTypeStatic,
    T9: ValidatableTypeStatic, T10: ValidatableTypeStatic, T11: ValidatableTypeStatic, T12: ValidatableTypeStatic,
    T13: ValidatableTypeStatic, T14: ValidatableTypeStatic, T15: ValidatableTypeStatic
{
    @inlinable
    public static func validate(type: TypeDefinition) -> Result<Void, TypeError>
    {
        validateTuple(type: type)
    }
}
