//
//  Tuples+Identifiable.swift
//  
//
//  Created by Yehor Popovych on 03/09/2023.
//

import Foundation
import Tuples

public protocol IdentifiableTuple: IdentifiableTypeStatic, SomeTuple {
    static func fillFieldDefinifions(defs: inout [TypeDefinition.Field])
}

public extension SomeTuple0 {
    @inlinable
    static var definition: TypeDefinition { .void }
    @inlinable
    static func fillFieldDefinifions(defs: inout [TypeDefinition.Field]) {}
}

public extension ListTuple where Self: IdentifiableTuple,
    DroppedLast: IdentifiableTuple, Last: IdentifiableTypeStatic
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

extension Tuple1: IdentifiableTuple, IdentifiableTypeStatic where T1: IdentifiableTypeStatic {}

extension Tuple2: IdentifiableTuple, IdentifiableTypeStatic where
    T1: IdentifiableTypeStatic, T2: IdentifiableTypeStatic {}

extension Tuple3: IdentifiableTuple, IdentifiableTypeStatic where
    T1: IdentifiableTypeStatic, T2: IdentifiableTypeStatic, T3: IdentifiableTypeStatic {}

extension Tuple4: IdentifiableTuple, IdentifiableTypeStatic where
    T1: IdentifiableTypeStatic, T2: IdentifiableTypeStatic, T3: IdentifiableTypeStatic,
    T4: IdentifiableTypeStatic {}

extension Tuple5: IdentifiableTuple, IdentifiableTypeStatic where
    T1: IdentifiableTypeStatic, T2: IdentifiableTypeStatic, T3: IdentifiableTypeStatic,
    T4: IdentifiableTypeStatic, T5: IdentifiableTypeStatic {}

extension Tuple6: IdentifiableTuple, IdentifiableTypeStatic where
    T1: IdentifiableTypeStatic, T2: IdentifiableTypeStatic, T3: IdentifiableTypeStatic,
    T4: IdentifiableTypeStatic, T5: IdentifiableTypeStatic, T6: IdentifiableTypeStatic {}

extension Tuple7: IdentifiableTuple, IdentifiableTypeStatic where
    T1: IdentifiableTypeStatic, T2: IdentifiableTypeStatic, T3: IdentifiableTypeStatic,
    T4: IdentifiableTypeStatic, T5: IdentifiableTypeStatic, T6: IdentifiableTypeStatic,
    T7: IdentifiableTypeStatic {}

extension Tuple8: IdentifiableTuple, IdentifiableTypeStatic where
    T1: IdentifiableTypeStatic, T2: IdentifiableTypeStatic, T3: IdentifiableTypeStatic,
    T4: IdentifiableTypeStatic, T5: IdentifiableTypeStatic, T6: IdentifiableTypeStatic,
    T7: IdentifiableTypeStatic, T8: IdentifiableTypeStatic {}

extension Tuple9: IdentifiableTuple, IdentifiableTypeStatic where
    T1: IdentifiableTypeStatic, T2: IdentifiableTypeStatic, T3: IdentifiableTypeStatic,
    T4: IdentifiableTypeStatic, T5: IdentifiableTypeStatic, T6: IdentifiableTypeStatic,
    T7: IdentifiableTypeStatic, T8: IdentifiableTypeStatic, T9: IdentifiableTypeStatic {}

extension Tuple10: IdentifiableTuple, IdentifiableTypeStatic where
    T1: IdentifiableTypeStatic, T2: IdentifiableTypeStatic, T3: IdentifiableTypeStatic,
    T4: IdentifiableTypeStatic, T5: IdentifiableTypeStatic, T6: IdentifiableTypeStatic,
    T7: IdentifiableTypeStatic, T8: IdentifiableTypeStatic, T9: IdentifiableTypeStatic,
    T10: IdentifiableTypeStatic {}

extension Tuple11: IdentifiableTuple, IdentifiableTypeStatic where
    T1: IdentifiableTypeStatic, T2: IdentifiableTypeStatic, T3: IdentifiableTypeStatic,
    T4: IdentifiableTypeStatic, T5: IdentifiableTypeStatic, T6: IdentifiableTypeStatic,
    T7: IdentifiableTypeStatic, T8: IdentifiableTypeStatic, T9: IdentifiableTypeStatic,
    T10: IdentifiableTypeStatic, T11: IdentifiableTypeStatic {}

extension Tuple12: IdentifiableTuple, IdentifiableTypeStatic where
    T1: IdentifiableTypeStatic, T2: IdentifiableTypeStatic, T3: IdentifiableTypeStatic,
    T4: IdentifiableTypeStatic, T5: IdentifiableTypeStatic, T6: IdentifiableTypeStatic,
    T7: IdentifiableTypeStatic, T8: IdentifiableTypeStatic, T9: IdentifiableTypeStatic,
    T10: IdentifiableTypeStatic, T11: IdentifiableTypeStatic, T12: IdentifiableTypeStatic {}

extension Tuple13: IdentifiableTuple, IdentifiableTypeStatic where
    T1: IdentifiableTypeStatic, T2: IdentifiableTypeStatic, T3: IdentifiableTypeStatic,
    T4: IdentifiableTypeStatic, T5: IdentifiableTypeStatic, T6: IdentifiableTypeStatic,
    T7: IdentifiableTypeStatic, T8: IdentifiableTypeStatic, T9: IdentifiableTypeStatic,
    T10: IdentifiableTypeStatic, T11: IdentifiableTypeStatic, T12: IdentifiableTypeStatic,
    T13: IdentifiableTypeStatic {}

extension Tuple14: IdentifiableTuple, IdentifiableTypeStatic where
    T1: IdentifiableTypeStatic, T2: IdentifiableTypeStatic, T3: IdentifiableTypeStatic,
    T4: IdentifiableTypeStatic, T5: IdentifiableTypeStatic, T6: IdentifiableTypeStatic,
    T7: IdentifiableTypeStatic, T8: IdentifiableTypeStatic, T9: IdentifiableTypeStatic,
    T10: IdentifiableTypeStatic, T11: IdentifiableTypeStatic, T12: IdentifiableTypeStatic,
    T13: IdentifiableTypeStatic, T14: IdentifiableTypeStatic {}

extension Tuple15: IdentifiableTuple, IdentifiableTypeStatic where
    T1: IdentifiableTypeStatic, T2: IdentifiableTypeStatic, T3: IdentifiableTypeStatic,
    T4: IdentifiableTypeStatic, T5: IdentifiableTypeStatic, T6: IdentifiableTypeStatic,
    T7: IdentifiableTypeStatic, T8: IdentifiableTypeStatic, T9: IdentifiableTypeStatic,
    T10: IdentifiableTypeStatic, T11: IdentifiableTypeStatic, T12: IdentifiableTypeStatic,
    T13: IdentifiableTypeStatic, T14: IdentifiableTypeStatic, T15: IdentifiableTypeStatic {}
