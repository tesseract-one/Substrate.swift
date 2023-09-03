//
//  Tuples+Validatable.swift
//  
//
//  Created by Yehor Popovych on 03/09/2023.
//

import Foundation
import Tuples

public protocol ValidatableTuple: ValidatableType, SomeTuple {
    static func validate(type: NetworkType.Info,
                         fields: [NetworkType.Info],
                         runtime: any Runtime) -> Result<Void, TypeError>
}

public extension SomeTuple0 {
    @inlinable
    static func validate(runtime: Runtime,
                         type: NetworkType.Info) -> Result<Void, TypeError>
    {
        type.type.isEmpty(runtime) ?
            .success(()) : .failure(.wrongType(for: Self.self, got: type.type,
                                               reason: "Expected ()"))
    }
    
    static func validate(type: NetworkType.Info,
                         fields: [NetworkType.Info],
                         runtime: any Runtime) -> Result<Void, TypeError>
    {
        fields.count == 0 ? .success(()) : .failure(.wrongValuesCount(for: Self.self,
                                                                      expected: 0,
                                                                      in: type.type))
    }
}

public extension ListTuple where DroppedLast: ValidatableTuple, Last: ValidatableType {
    @inlinable
    static func validate(runtime: Runtime,
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
            return validate(type: type,
                            fields: Array(repeating: chType.i(id), count: Int(count)),
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
            }.flatMap { validate(type: type, fields: $0, runtime: runtime) }
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
            }.flatMap { validate(type: type, fields: $0, runtime: runtime) }
        default:
            return .failure(.wrongType(for: Self.self,
                                       got: type.type,
                                       reason: "Isn't composite"))
        }
    }
    
    static func validate(type: NetworkType.Info,
                         fields: [NetworkType.Info],
                         runtime: any Runtime) -> Result<Void, TypeError>
    {
        guard fields.count == self.count else {
            return .failure(.wrongValuesCount(for: Self.self,
                                              expected: self.count, in: type.type))
        }
        var fields = fields
        let ltype = fields.removeLast()
        return DroppedLast.validate(type: type, fields: fields, runtime: runtime).flatMap {
            Last.validate(runtime: runtime, type: ltype)
        }
    }
}

extension Tuple0: ValidatableTuple {}

extension Tuple1: ValidatableTuple, ValidatableType where T1: ValidatableType {}

extension Tuple2: ValidatableTuple, ValidatableType where
    T1: ValidatableType, T2: ValidatableType {}

extension Tuple3: ValidatableTuple, ValidatableType where
    T1: ValidatableType, T2: ValidatableType, T3: ValidatableType {}

extension Tuple4: ValidatableTuple, ValidatableType where
    T1: ValidatableType, T2: ValidatableType, T3: ValidatableType, T4: ValidatableType {}

extension Tuple5: ValidatableTuple, ValidatableType where
    T1: ValidatableType, T2: ValidatableType, T3: ValidatableType, T4: ValidatableType,
    T5: ValidatableType {}

extension Tuple6: ValidatableTuple, ValidatableType where
    T1: ValidatableType, T2: ValidatableType, T3: ValidatableType, T4: ValidatableType,
    T5: ValidatableType, T6: ValidatableType {}

extension Tuple7: ValidatableTuple, ValidatableType where
    T1: ValidatableType, T2: ValidatableType, T3: ValidatableType, T4: ValidatableType,
    T5: ValidatableType, T6: ValidatableType, T7: ValidatableType {}

extension Tuple8: ValidatableTuple, ValidatableType where
    T1: ValidatableType, T2: ValidatableType, T3: ValidatableType, T4: ValidatableType,
    T5: ValidatableType, T6: ValidatableType, T7: ValidatableType, T8: ValidatableType {}

extension Tuple9: ValidatableTuple, ValidatableType where
    T1: ValidatableType, T2: ValidatableType, T3: ValidatableType, T4: ValidatableType,
    T5: ValidatableType, T6: ValidatableType, T7: ValidatableType, T8: ValidatableType,
    T9: ValidatableType {}

extension Tuple10: ValidatableTuple, ValidatableType where
    T1: ValidatableType, T2: ValidatableType, T3: ValidatableType, T4: ValidatableType,
    T5: ValidatableType, T6: ValidatableType, T7: ValidatableType, T8: ValidatableType,
    T9: ValidatableType, T10: ValidatableType {}

extension Tuple11: ValidatableTuple, ValidatableType where
    T1: ValidatableType, T2: ValidatableType, T3: ValidatableType, T4: ValidatableType,
    T5: ValidatableType, T6: ValidatableType, T7: ValidatableType, T8: ValidatableType,
    T9: ValidatableType, T10: ValidatableType, T11: ValidatableType {}

extension Tuple12: ValidatableTuple, ValidatableType where
    T1: ValidatableType, T2: ValidatableType, T3: ValidatableType, T4: ValidatableType,
    T5: ValidatableType, T6: ValidatableType, T7: ValidatableType, T8: ValidatableType,
    T9: ValidatableType, T10: ValidatableType, T11: ValidatableType, T12: ValidatableType {}

extension Tuple13: ValidatableTuple, ValidatableType where
    T1: ValidatableType, T2: ValidatableType, T3: ValidatableType, T4: ValidatableType,
    T5: ValidatableType, T6: ValidatableType, T7: ValidatableType, T8: ValidatableType,
    T9: ValidatableType, T10: ValidatableType, T11: ValidatableType, T12: ValidatableType,
    T13: ValidatableType {}

extension Tuple14: ValidatableTuple, ValidatableType where
    T1: ValidatableType, T2: ValidatableType, T3: ValidatableType, T4: ValidatableType,
    T5: ValidatableType, T6: ValidatableType, T7: ValidatableType, T8: ValidatableType,
    T9: ValidatableType, T10: ValidatableType, T11: ValidatableType, T12: ValidatableType,
    T13: ValidatableType, T14: ValidatableType {}

extension Tuple15: ValidatableTuple, ValidatableType where
    T1: ValidatableType, T2: ValidatableType, T3: ValidatableType, T4: ValidatableType,
    T5: ValidatableType, T6: ValidatableType, T7: ValidatableType, T8: ValidatableType,
    T9: ValidatableType, T10: ValidatableType, T11: ValidatableType, T12: ValidatableType,
    T13: ValidatableType, T14: ValidatableType, T15: ValidatableType {}
