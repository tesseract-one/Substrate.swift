//
//  Tuples+ValidatableDynamic.swift
//  
//
//  Created by Yehor Popovych on 05/09/2023.
//

import Foundation
import Tuples

public protocol ValidatableTupleDynamic: ValidatableTypeDynamic, SomeTuple {
    func validate(runtime: any Runtime,
                  type: TypeDefinition,
                  fields: inout [TypeDefinition.Field]) -> Result<Void, TypeError>
}

public extension SomeTuple0 {
    @inlinable
     func dynamicValidateTuple(runtime: any Runtime,
                               type: TypeDefinition) -> Result<Void, TypeError>
    {
        type.isEmpty() ?
            .success(()) : .failure(.wrongType(for: Self.self, type: type,
                                               reason: "Expected empty", .get()))
    }
    
    @inlinable
    func validate(runtime: any Runtime,
                  type: TypeDefinition,
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
    func dynamicValidateTuple(runtime: any Runtime,
                              type: TypeDefinition) -> Result<Void, TypeError>
    {
        switch type.definition {
        case .array(count: let count, of: let chType):
            guard count == self.count else {
                return .failure(.wrongValuesCount(for: Self.self,
                                                  expected: self.count,
                                                  type: type, .get()))
            }
            var fields = Array(repeating: TypeDefinition.Field.v(chType), count: Int(count))
            return validate(runtime: runtime, type: type, fields: &fields)
        case .composite(fields: var fields):
            guard fields.count == self.count else {
                return .failure(.wrongValuesCount(for: Self.self,
                                                  expected: self.count,
                                                  type: type, .get()))
            }
            return validate(runtime: runtime, type: type, fields: &fields)
        default:
            return .failure(.wrongType(for: Self.self,
                                       type: type,
                                       reason: "Isn't composite", .get()))
        }
    }
    
    @inlinable
    func validate(runtime: any Runtime,
                  type: TypeDefinition,
                  fields: inout [TypeDefinition.Field]) -> Result<Void, TypeError>
    {
        guard fields.count == self.count else {
            return .failure(.wrongValuesCount(for: Self.self,
                                              expected: self.count,
                                              type: type, .get()))
        }
        let ltype = fields.removeLast()
        return dropLast.validate(runtime: runtime, type: type, fields: &fields).flatMap {
            last.validate(runtime: runtime, type: ltype.type)
        }
    }
}

extension Tuple0: ValidatableTupleDynamic {}

extension Tuple1: ValidatableTupleDynamic, ValidatableTypeDynamic where T1: ValidatableTypeDynamic {
    @inlinable
    public func validate(runtime: Runtime, type: TypeDefinition) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: type)
    }
}

extension Tuple2: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic
{
    @inlinable
    public func validate(runtime: Runtime, type: TypeDefinition) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: type)
    }
}

extension Tuple3: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic
{
    @inlinable
    public func validate(runtime: Runtime, type: TypeDefinition) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: type)
    }
}

extension Tuple4: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic
{
    public func validate(runtime: Runtime, type: TypeDefinition) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: type)
    }
}

extension Tuple5: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic
{
    public func validate(runtime: Runtime, type: TypeDefinition) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: type)
    }
}

extension Tuple6: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic
{
    public func validate(runtime: Runtime, type: TypeDefinition) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: type)
    }
}

extension Tuple7: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic
{
    public func validate(runtime: Runtime, type: TypeDefinition) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: type)
    }
}

extension Tuple8: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic, T8: ValidatableTypeDynamic
{
    public func validate(runtime: Runtime, type: TypeDefinition) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: type)
    }
}

extension Tuple9: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic, T8: ValidatableTypeDynamic, T9: ValidatableTypeDynamic
{
    public func validate(runtime: Runtime, type: TypeDefinition) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: type)
    }
}

extension Tuple10: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic, T8: ValidatableTypeDynamic, T9: ValidatableTypeDynamic,
    T10: ValidatableTypeDynamic
{
    public func validate(runtime: Runtime, type: TypeDefinition) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: type)
    }
}

extension Tuple11: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic, T8: ValidatableTypeDynamic, T9: ValidatableTypeDynamic,
    T10: ValidatableTypeDynamic, T11: ValidatableTypeDynamic
{
    public func validate(runtime: Runtime, type: TypeDefinition) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: type)
    }
}

extension Tuple12: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic, T8: ValidatableTypeDynamic, T9: ValidatableTypeDynamic,
    T10: ValidatableTypeDynamic, T11: ValidatableTypeDynamic, T12: ValidatableTypeDynamic
{
    public func validate(runtime: Runtime, type: TypeDefinition) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: type)
    }
}

extension Tuple13: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic, T8: ValidatableTypeDynamic, T9: ValidatableTypeDynamic,
    T10: ValidatableTypeDynamic, T11: ValidatableTypeDynamic, T12: ValidatableTypeDynamic,
    T13: ValidatableTypeDynamic
{
    public func validate(runtime: Runtime, type: TypeDefinition) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: type)
    }
}

extension Tuple14: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic, T8: ValidatableTypeDynamic, T9: ValidatableTypeDynamic,
    T10: ValidatableTypeDynamic, T11: ValidatableTypeDynamic, T12: ValidatableTypeDynamic,
    T13: ValidatableTypeDynamic, T14: ValidatableTypeDynamic
{
    public func validate(runtime: Runtime, type: TypeDefinition) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: type)
    }
}

extension Tuple15: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic, T8: ValidatableTypeDynamic, T9: ValidatableTypeDynamic,
    T10: ValidatableTypeDynamic, T11: ValidatableTypeDynamic, T12: ValidatableTypeDynamic,
    T13: ValidatableTypeDynamic, T14: ValidatableTypeDynamic, T15: ValidatableTypeDynamic
{
    public func validate(runtime: Runtime, type: TypeDefinition) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: type)
    }
}
