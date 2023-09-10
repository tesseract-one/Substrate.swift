//
//  Tuples+ValidatableDynamic.swift
//  
//
//  Created by Yehor Popovych on 05/09/2023.
//

import Foundation
import Tuples

public protocol ValidatableTupleDynamic: ValidatableTypeDynamic, SomeTuple {
    func validate(as type: TypeDefinition,
                  in runtime: any Runtime,
                  fields: inout [TypeDefinition.Field]) -> Result<Void, TypeError>
}

public extension SomeTuple0 {
    @inlinable
     func dynamicValidateTuple(as type: TypeDefinition,
                               in runtime: any Runtime) -> Result<Void, TypeError>
    {
        type.isEmpty() ?
            .success(()) : .failure(.wrongType(for: Self.self, type: type,
                                               reason: "Expected empty", .get()))
    }
    
    @inlinable
    func validate(as type: TypeDefinition,
                  in runtime: any Runtime,
                  fields: inout [TypeDefinition.Field]) -> Result<Void, TypeError>
    {
        fields.count == 0 ? .success(()) : .failure(.wrongValuesCount(for: Self.self,
                                                                      expected: 0,
                                                                      type: type,
                                                                      .get()))
    }
}

public extension ListTuple where DroppedLast: ValidatableTupleDynamic,
                                 Last: ValidatableTypeDynamic
{
    func dynamicValidateTuple(as type: TypeDefinition,
                              in runtime: any Runtime) -> Result<Void, TypeError>
    {
        switch type.definition {
        case .array(count: let count, of: let chType):
            guard count == self.count else {
                return .failure(.wrongValuesCount(for: Self.self,
                                                  expected: self.count,
                                                  type: type, .get()))
            }
            var fields = Array(repeating: TypeDefinition.Field.v(chType), count: Int(count))
            return validate(as: type, in: runtime, fields: &fields)
        case .composite(fields: var fields):
            guard fields.count == self.count else {
                return .failure(.wrongValuesCount(for: Self.self,
                                                  expected: self.count,
                                                  type: type, .get()))
            }
            return validate(as: type, in: runtime, fields: &fields)
        default:
            return .failure(.wrongType(for: Self.self,
                                       type: type,
                                       reason: "Isn't composite", .get()))
        }
    }
    
    @inlinable
    func validate(as type: TypeDefinition,
                  in runtime: any Runtime,
                  fields: inout [TypeDefinition.Field]) -> Result<Void, TypeError>
    {
        guard fields.count == self.count else {
            return .failure(.wrongValuesCount(for: Self.self,
                                              expected: self.count,
                                              type: type, .get()))
        }
        let ltype = fields.removeLast()
        return dropLast.validate(as: type, in: runtime, fields: &fields).flatMap {
            last.validate(as: *ltype.type, in: runtime)
        }
    }
}

extension Tuple0: ValidatableTupleDynamic {}

extension Tuple1: ValidatableTupleDynamic, ValidatableTypeDynamic where T1: ValidatableTypeDynamic {
    @inlinable
    public func validate(as type: TypeDefinition, in runtime: Runtime) -> Result<Void, TypeError> {
        dynamicValidateTuple(as: type, in: runtime)
    }
}

extension Tuple2: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic
{
    @inlinable
    public func validate(as type: TypeDefinition, in runtime: Runtime) -> Result<Void, TypeError> {
        dynamicValidateTuple(as: type, in: runtime)
    }
}

extension Tuple3: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic
{
    @inlinable
    public func validate(as type: TypeDefinition, in runtime: Runtime) -> Result<Void, TypeError> {
        dynamicValidateTuple(as: type, in: runtime)
    }
}

extension Tuple4: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic
{
    public func validate(as type: TypeDefinition, in runtime: Runtime) -> Result<Void, TypeError> {
        dynamicValidateTuple(as: type, in: runtime)
    }
}

extension Tuple5: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic
{
    public func validate(as type: TypeDefinition, in runtime: Runtime) -> Result<Void, TypeError> {
        dynamicValidateTuple(as: type, in: runtime)
    }
}

extension Tuple6: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic
{
    public func validate(as type: TypeDefinition, in runtime: Runtime) -> Result<Void, TypeError> {
        dynamicValidateTuple(as: type, in: runtime)
    }
}

extension Tuple7: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic
{
    public func validate(as type: TypeDefinition, in runtime: Runtime) -> Result<Void, TypeError> {
        dynamicValidateTuple(as: type, in: runtime)
    }
}

extension Tuple8: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic, T8: ValidatableTypeDynamic
{
    public func validate(as type: TypeDefinition, in runtime: Runtime) -> Result<Void, TypeError> {
        dynamicValidateTuple(as: type, in: runtime)
    }
}

extension Tuple9: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic, T8: ValidatableTypeDynamic, T9: ValidatableTypeDynamic
{
    public func validate(as type: TypeDefinition, in runtime: Runtime) -> Result<Void, TypeError> {
        dynamicValidateTuple(as: type, in: runtime)
    }
}

extension Tuple10: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic, T8: ValidatableTypeDynamic, T9: ValidatableTypeDynamic,
    T10: ValidatableTypeDynamic
{
    public func validate(as type: TypeDefinition, in runtime: Runtime) -> Result<Void, TypeError> {
        dynamicValidateTuple(as: type, in: runtime)
    }
}

extension Tuple11: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic, T8: ValidatableTypeDynamic, T9: ValidatableTypeDynamic,
    T10: ValidatableTypeDynamic, T11: ValidatableTypeDynamic
{
    public func validate(as type: TypeDefinition, in runtime: Runtime) -> Result<Void, TypeError> {
        dynamicValidateTuple(as: type, in: runtime)
    }
}

extension Tuple12: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic, T8: ValidatableTypeDynamic, T9: ValidatableTypeDynamic,
    T10: ValidatableTypeDynamic, T11: ValidatableTypeDynamic, T12: ValidatableTypeDynamic
{
    public func validate(as type: TypeDefinition, in runtime: Runtime) -> Result<Void, TypeError> {
        dynamicValidateTuple(as: type, in: runtime)
    }
}

extension Tuple13: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic, T8: ValidatableTypeDynamic, T9: ValidatableTypeDynamic,
    T10: ValidatableTypeDynamic, T11: ValidatableTypeDynamic, T12: ValidatableTypeDynamic,
    T13: ValidatableTypeDynamic
{
    public func validate(as type: TypeDefinition, in runtime: Runtime) -> Result<Void, TypeError> {
        dynamicValidateTuple(as: type, in: runtime)
    }
}

extension Tuple14: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic, T8: ValidatableTypeDynamic, T9: ValidatableTypeDynamic,
    T10: ValidatableTypeDynamic, T11: ValidatableTypeDynamic, T12: ValidatableTypeDynamic,
    T13: ValidatableTypeDynamic, T14: ValidatableTypeDynamic
{
    public func validate(as type: TypeDefinition, in runtime: Runtime) -> Result<Void, TypeError> {
        dynamicValidateTuple(as: type, in: runtime)
    }
}

extension Tuple15: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic, T8: ValidatableTypeDynamic, T9: ValidatableTypeDynamic,
    T10: ValidatableTypeDynamic, T11: ValidatableTypeDynamic, T12: ValidatableTypeDynamic,
    T13: ValidatableTypeDynamic, T14: ValidatableTypeDynamic, T15: ValidatableTypeDynamic
{
    public func validate(as type: TypeDefinition, in runtime: Runtime) -> Result<Void, TypeError> {
        dynamicValidateTuple(as: type, in: runtime)
    }
}
