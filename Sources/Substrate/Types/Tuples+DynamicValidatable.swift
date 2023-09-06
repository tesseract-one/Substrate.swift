//
//  Tuples+DynamicValidatable.swift
//  
//
//  Created by Yehor Popovych on 05/09/2023.
//

import Foundation
import Tuples

public protocol DynamicValidatableTuple: DynamicValidatableType, SomeTuple {
    func validate(runtime: any Runtime,
                  type: NetworkType.Info,
                  fields: inout [NetworkType.Info]) -> Result<Void, TypeError>
}

public extension SomeTuple0 {
    @inlinable
     func dynamicValidateTuple(runtime: Runtime,
                               type: NetworkType.Info) -> Result<Void, TypeError>
    {
        type.type.isEmpty(runtime) ?
            .success(()) : .failure(.wrongType(for: Self.self, got: type.type,
                                               reason: "Expected ()"))
    }
    
    @inlinable
    func validate(runtime: any Runtime,
                  type: NetworkType.Info,
                  fields: inout [NetworkType.Info]) -> Result<Void, TypeError>
    {
        fields.count == 0 ? .success(()) : .failure(.wrongValuesCount(for: Self.self,
                                                                      expected: 0,
                                                                      in: type.type))
    }
}

public extension ListTuple where DroppedLast: DynamicValidatableTuple,
                                 Last: DynamicValidatableType
{
    func dynamicValidateTuple(runtime: Runtime,
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
            return validate(runtime: runtime, type: type, fields: &fields )
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
                return validate(runtime: runtime, type: type, fields: &fields)
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
                return validate(runtime: runtime, type: type, fields: &fields)
            }
        default:
            return .failure(.wrongType(for: Self.self,
                                       got: type.type,
                                       reason: "Isn't composite"))
        }
    }
    
    @inlinable
    func validate(runtime: any Runtime,
                  type: NetworkType.Info,
                  fields: inout [NetworkType.Info]) -> Result<Void, TypeError>
    {
        guard fields.count == self.count else {
            return .failure(.wrongValuesCount(for: Self.self,
                                              expected: self.count, in: type.type))
        }
        let ltype = fields.removeLast()
        return dropLast.validate(runtime: runtime, type: type, fields: &fields).flatMap {
            last.validate(runtime: runtime, type: ltype)
        }
    }
}

extension Tuple0: DynamicValidatableTuple {}

extension Tuple1: DynamicValidatableTuple, DynamicValidatableType where T1: DynamicValidatableType {
    @inlinable
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple2: DynamicValidatableTuple, DynamicValidatableType where
    T1: DynamicValidatableType, T2: DynamicValidatableType
{
    @inlinable
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple3: DynamicValidatableTuple, DynamicValidatableType where
    T1: DynamicValidatableType, T2: DynamicValidatableType, T3: DynamicValidatableType
{
    @inlinable
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple4: DynamicValidatableTuple, DynamicValidatableType where
    T1: DynamicValidatableType, T2: DynamicValidatableType, T3: DynamicValidatableType,
    T4: DynamicValidatableType
{
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple5: DynamicValidatableTuple, DynamicValidatableType where
    T1: DynamicValidatableType, T2: DynamicValidatableType, T3: DynamicValidatableType,
    T4: DynamicValidatableType, T5: DynamicValidatableType
{
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple6: DynamicValidatableTuple, DynamicValidatableType where
    T1: DynamicValidatableType, T2: DynamicValidatableType, T3: DynamicValidatableType,
    T4: DynamicValidatableType, T5: DynamicValidatableType, T6: DynamicValidatableType
{
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple7: DynamicValidatableTuple, DynamicValidatableType where
    T1: DynamicValidatableType, T2: DynamicValidatableType, T3: DynamicValidatableType,
    T4: DynamicValidatableType, T5: DynamicValidatableType, T6: DynamicValidatableType,
    T7: DynamicValidatableType
{
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple8: DynamicValidatableTuple, DynamicValidatableType where
    T1: DynamicValidatableType, T2: DynamicValidatableType, T3: DynamicValidatableType,
    T4: DynamicValidatableType, T5: DynamicValidatableType, T6: DynamicValidatableType,
    T7: DynamicValidatableType, T8: DynamicValidatableType
{
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple9: DynamicValidatableTuple, DynamicValidatableType where
    T1: DynamicValidatableType, T2: DynamicValidatableType, T3: DynamicValidatableType,
    T4: DynamicValidatableType, T5: DynamicValidatableType, T6: DynamicValidatableType,
    T7: DynamicValidatableType, T8: DynamicValidatableType, T9: DynamicValidatableType
{
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple10: DynamicValidatableTuple, DynamicValidatableType where
    T1: DynamicValidatableType, T2: DynamicValidatableType, T3: DynamicValidatableType,
    T4: DynamicValidatableType, T5: DynamicValidatableType, T6: DynamicValidatableType,
    T7: DynamicValidatableType, T8: DynamicValidatableType, T9: DynamicValidatableType,
    T10: DynamicValidatableType
{
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple11: DynamicValidatableTuple, DynamicValidatableType where
    T1: DynamicValidatableType, T2: DynamicValidatableType, T3: DynamicValidatableType,
    T4: DynamicValidatableType, T5: DynamicValidatableType, T6: DynamicValidatableType,
    T7: DynamicValidatableType, T8: DynamicValidatableType, T9: DynamicValidatableType,
    T10: DynamicValidatableType, T11: DynamicValidatableType
{
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple12: DynamicValidatableTuple, DynamicValidatableType where
    T1: DynamicValidatableType, T2: DynamicValidatableType, T3: DynamicValidatableType,
    T4: DynamicValidatableType, T5: DynamicValidatableType, T6: DynamicValidatableType,
    T7: DynamicValidatableType, T8: DynamicValidatableType, T9: DynamicValidatableType,
    T10: DynamicValidatableType, T11: DynamicValidatableType, T12: DynamicValidatableType
{
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple13: DynamicValidatableTuple, DynamicValidatableType where
    T1: DynamicValidatableType, T2: DynamicValidatableType, T3: DynamicValidatableType,
    T4: DynamicValidatableType, T5: DynamicValidatableType, T6: DynamicValidatableType,
    T7: DynamicValidatableType, T8: DynamicValidatableType, T9: DynamicValidatableType,
    T10: DynamicValidatableType, T11: DynamicValidatableType, T12: DynamicValidatableType,
    T13: DynamicValidatableType
{
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple14: DynamicValidatableTuple, DynamicValidatableType where
    T1: DynamicValidatableType, T2: DynamicValidatableType, T3: DynamicValidatableType,
    T4: DynamicValidatableType, T5: DynamicValidatableType, T6: DynamicValidatableType,
    T7: DynamicValidatableType, T8: DynamicValidatableType, T9: DynamicValidatableType,
    T10: DynamicValidatableType, T11: DynamicValidatableType, T12: DynamicValidatableType,
    T13: DynamicValidatableType, T14: DynamicValidatableType
{
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple15: DynamicValidatableTuple, DynamicValidatableType where
    T1: DynamicValidatableType, T2: DynamicValidatableType, T3: DynamicValidatableType,
    T4: DynamicValidatableType, T5: DynamicValidatableType, T6: DynamicValidatableType,
    T7: DynamicValidatableType, T8: DynamicValidatableType, T9: DynamicValidatableType,
    T10: DynamicValidatableType, T11: DynamicValidatableType, T12: DynamicValidatableType,
    T13: DynamicValidatableType, T14: DynamicValidatableType, T15: DynamicValidatableType
{
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}
