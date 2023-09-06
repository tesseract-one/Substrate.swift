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
                  type: NetworkType.Info,
                  fields: inout [NetworkType.Info]) -> Result<Void, TypeError>
}

public extension SomeTuple0 {
    @inlinable
     func dynamicValidateTuple(runtime: Runtime,
                               type: NetworkType.Info) -> Result<Void, TypeError>
    {
        type.type.isEmpty(runtime) ?
            .success(()) : .failure(.wrongType(for: Self.self, type: type.type,
                                               reason: "Expected ()", .get()))
    }
    
    @inlinable
    func validate(runtime: any Runtime,
                  type: NetworkType.Info,
                  fields: inout [NetworkType.Info]) -> Result<Void, TypeError>
    {
        fields.count == 0 ? .success(()) : .failure(.wrongValuesCount(for: Self.self,
                                                                      expected: 0,
                                                                      type: type.type,
                                                                      .get()))
    }
}

public extension ListTuple where DroppedLast: ValidatableTupleDynamic,
                                 Last: ValidatableTypeDynamic
{
    func dynamicValidateTuple(runtime: Runtime,
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
            return validate(runtime: runtime, type: type, fields: &fields )
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
                return validate(runtime: runtime, type: type, fields: &fields)
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
                return validate(runtime: runtime, type: type, fields: &fields)
            }
        default:
            return .failure(.wrongType(for: Self.self,
                                       type: type.type,
                                       reason: "Isn't composite", .get()))
        }
    }
    
    @inlinable
    func validate(runtime: any Runtime,
                  type: NetworkType.Info,
                  fields: inout [NetworkType.Info]) -> Result<Void, TypeError>
    {
        guard fields.count == self.count else {
            return .failure(.wrongValuesCount(for: Self.self,
                                              expected: self.count,
                                              type: type.type, .get()))
        }
        let ltype = fields.removeLast()
        return dropLast.validate(runtime: runtime, type: type, fields: &fields).flatMap {
            last.validate(runtime: runtime, type: ltype)
        }
    }
}

extension Tuple0: ValidatableTupleDynamic {}

extension Tuple1: ValidatableTupleDynamic, ValidatableTypeDynamic where T1: ValidatableTypeDynamic {
    @inlinable
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple2: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic
{
    @inlinable
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple3: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic
{
    @inlinable
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple4: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic
{
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple5: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic
{
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple6: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic
{
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple7: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic
{
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple8: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic, T8: ValidatableTypeDynamic
{
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple9: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic, T8: ValidatableTypeDynamic, T9: ValidatableTypeDynamic
{
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple10: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic, T8: ValidatableTypeDynamic, T9: ValidatableTypeDynamic,
    T10: ValidatableTypeDynamic
{
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple11: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic, T8: ValidatableTypeDynamic, T9: ValidatableTypeDynamic,
    T10: ValidatableTypeDynamic, T11: ValidatableTypeDynamic
{
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple12: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic, T8: ValidatableTypeDynamic, T9: ValidatableTypeDynamic,
    T10: ValidatableTypeDynamic, T11: ValidatableTypeDynamic, T12: ValidatableTypeDynamic
{
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple13: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic, T8: ValidatableTypeDynamic, T9: ValidatableTypeDynamic,
    T10: ValidatableTypeDynamic, T11: ValidatableTypeDynamic, T12: ValidatableTypeDynamic,
    T13: ValidatableTypeDynamic
{
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple14: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic, T8: ValidatableTypeDynamic, T9: ValidatableTypeDynamic,
    T10: ValidatableTypeDynamic, T11: ValidatableTypeDynamic, T12: ValidatableTypeDynamic,
    T13: ValidatableTypeDynamic, T14: ValidatableTypeDynamic
{
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}

extension Tuple15: ValidatableTupleDynamic, ValidatableTypeDynamic where
    T1: ValidatableTypeDynamic, T2: ValidatableTypeDynamic, T3: ValidatableTypeDynamic,
    T4: ValidatableTypeDynamic, T5: ValidatableTypeDynamic, T6: ValidatableTypeDynamic,
    T7: ValidatableTypeDynamic, T8: ValidatableTypeDynamic, T9: ValidatableTypeDynamic,
    T10: ValidatableTypeDynamic, T11: ValidatableTypeDynamic, T12: ValidatableTypeDynamic,
    T13: ValidatableTypeDynamic, T14: ValidatableTypeDynamic, T15: ValidatableTypeDynamic
{
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        dynamicValidateTuple(runtime: runtime, type: info)
    }
}
