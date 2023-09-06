//
//  Tuples+Identifiable.swift
//  
//
//  Created by Yehor Popovych on 03/09/2023.
//

import Foundation
import Tuples

public protocol IdentifiableTuple: IdentifiableType, SomeTuple {
    static func fillFieldDefinifions(defs: inout [TypeDefinition.Field])
}

public extension SomeTuple0 {
    @inlinable
    static var definition: TypeDefinition { .void }
    @inlinable
    static func fillFieldDefinifions(defs: inout [TypeDefinition.Field]) {}
}

public extension ListTuple where Self: IdentifiableTuple,
    DroppedLast: IdentifiableTuple, Last: IdentifiableType
{
    @inlinable
    static var definition: TypeDefinition {
        var fieldDefs = Array<TypeDefinition.Field>()
        fieldDefs.reserveCapacity(count)
        fillFieldDefinifions(defs: &fieldDefs)
        return .composite(fields: fieldDefs)
    }
    
    @inlinable
    static func fillFieldDefinifions(defs: inout [TypeDefinition.Field]) {
        DroppedLast.fillFieldDefinifions(defs: &defs)
        defs.append(.v(Last.definition))
    }
}

extension Tuple0: IdentifiableTuple {}

extension Tuple1: IdentifiableTuple, IdentifiableType where T1: IdentifiableType {}

extension Tuple2: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType {}

extension Tuple3: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType, T3: IdentifiableType {}

extension Tuple4: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType, T3: IdentifiableType,
    T4: IdentifiableType {}

extension Tuple5: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType, T3: IdentifiableType,
    T4: IdentifiableType, T5: IdentifiableType {}

extension Tuple6: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType, T3: IdentifiableType,
    T4: IdentifiableType, T5: IdentifiableType, T6: IdentifiableType {}

extension Tuple7: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType, T3: IdentifiableType,
    T4: IdentifiableType, T5: IdentifiableType, T6: IdentifiableType,
    T7: IdentifiableType {}

extension Tuple8: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType, T3: IdentifiableType,
    T4: IdentifiableType, T5: IdentifiableType, T6: IdentifiableType,
    T7: IdentifiableType, T8: IdentifiableType {}

extension Tuple9: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType, T3: IdentifiableType,
    T4: IdentifiableType, T5: IdentifiableType, T6: IdentifiableType,
    T7: IdentifiableType, T8: IdentifiableType, T9: IdentifiableType {}

extension Tuple10: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType, T3: IdentifiableType,
    T4: IdentifiableType, T5: IdentifiableType, T6: IdentifiableType,
    T7: IdentifiableType, T8: IdentifiableType, T9: IdentifiableType,
    T10: IdentifiableType {}

extension Tuple11: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType, T3: IdentifiableType,
    T4: IdentifiableType, T5: IdentifiableType, T6: IdentifiableType,
    T7: IdentifiableType, T8: IdentifiableType, T9: IdentifiableType,
    T10: IdentifiableType, T11: IdentifiableType {}

extension Tuple12: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType, T3: IdentifiableType,
    T4: IdentifiableType, T5: IdentifiableType, T6: IdentifiableType,
    T7: IdentifiableType, T8: IdentifiableType, T9: IdentifiableType,
    T10: IdentifiableType, T11: IdentifiableType, T12: IdentifiableType {}

extension Tuple13: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType, T3: IdentifiableType,
    T4: IdentifiableType, T5: IdentifiableType, T6: IdentifiableType,
    T7: IdentifiableType, T8: IdentifiableType, T9: IdentifiableType,
    T10: IdentifiableType, T11: IdentifiableType, T12: IdentifiableType,
    T13: IdentifiableType {}

extension Tuple14: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType, T3: IdentifiableType,
    T4: IdentifiableType, T5: IdentifiableType, T6: IdentifiableType,
    T7: IdentifiableType, T8: IdentifiableType, T9: IdentifiableType,
    T10: IdentifiableType, T11: IdentifiableType, T12: IdentifiableType,
    T13: IdentifiableType, T14: IdentifiableType {}

extension Tuple15: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType, T3: IdentifiableType,
    T4: IdentifiableType, T5: IdentifiableType, T6: IdentifiableType,
    T7: IdentifiableType, T8: IdentifiableType, T9: IdentifiableType,
    T10: IdentifiableType, T11: IdentifiableType, T12: IdentifiableType,
    T13: IdentifiableType, T14: IdentifiableType, T15: IdentifiableType {}
