//
//  Tuples+Identifiable.swift
//  
//
//  Created by Yehor Popovych on 03/09/2023.
//

import Foundation
import Tuples

public protocol IdentifiableTuple: IdentifiableType, SomeTuple {
    static var elementsFieldDefinifions: [TypeDefinition.Field] { get }
}

public extension SomeTuple0 {
    @inlinable
    static var definition: TypeDefinition { .void }
    @inlinable
    static var elementsFieldDefinifions: [TypeDefinition.Field] { [] }
}

public extension ListTuple where Self: IdentifiableTuple,
    DroppedLast: IdentifiableTuple, Last: IdentifiableType
{
    @inlinable
    static var definition: TypeDefinition {
        .composite(fields: elementsFieldDefinifions)
    }
    
    @inlinable
    static var elementsFieldDefinifions: [TypeDefinition.Field] {
        DroppedLast.elementsFieldDefinifions + [.init(nil, Last.definition)]
    }
}

extension Tuple0: IdentifiableTuple {
    public static func validate(runtime: any Runtime,
                                type: NetworkType.Info) -> Result<Void, TypeError>
    {
        definition.validate(runtime: runtime, type: type.type)
    }
}

extension Tuple1: IdentifiableTuple, IdentifiableType where T1: IdentifiableType {
    public static func validate(runtime: Runtime,
                                type: NetworkType.Info) -> Result<Void, TypeError>
    {
        definition.validate(runtime: runtime, type: type.type)
    }
}

extension Tuple2: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType
{
    public static func validate(runtime: Runtime,
                                type: NetworkType.Info) -> Result<Void, TypeError>
    {
        definition.validate(runtime: runtime, type: type.type)
    }
}

extension Tuple3: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType, T3: IdentifiableType
{
    public static func validate(runtime: Runtime,
                                type: NetworkType.Info) -> Result<Void, TypeError>
    {
        definition.validate(runtime: runtime, type: type.type)
    }
}

extension Tuple4: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType, T3: IdentifiableType,
    T4: IdentifiableType
{
    public static func validate(runtime: Runtime,
                                type: NetworkType.Info) -> Result<Void, TypeError>
    {
        definition.validate(runtime: runtime, type: type.type)
    }
}

extension Tuple5: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType, T3: IdentifiableType,
    T4: IdentifiableType, T5: IdentifiableType
{
    public static func validate(runtime: Runtime,
                                type: NetworkType.Info) -> Result<Void, TypeError>
    {
        definition.validate(runtime: runtime, type: type.type)
    }
}

extension Tuple6: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType, T3: IdentifiableType,
    T4: IdentifiableType, T5: IdentifiableType, T6: IdentifiableType
{
    public static func validate(runtime: Runtime,
                                type: NetworkType.Info) -> Result<Void, TypeError>
    {
        definition.validate(runtime: runtime, type: type.type)
    }
}

extension Tuple7: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType, T3: IdentifiableType,
    T4: IdentifiableType, T5: IdentifiableType, T6: IdentifiableType,
    T7: IdentifiableType
{
    public static func validate(runtime: Runtime,
                                type: NetworkType.Info) -> Result<Void, TypeError>
    {
        definition.validate(runtime: runtime, type: type.type)
    }
}

extension Tuple8: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType, T3: IdentifiableType,
    T4: IdentifiableType, T5: IdentifiableType, T6: IdentifiableType,
    T7: IdentifiableType, T8: IdentifiableType
{
    public static func validate(runtime: Runtime,
                                type: NetworkType.Info) -> Result<Void, TypeError>
    {
        definition.validate(runtime: runtime, type: type.type)
    }
}

extension Tuple9: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType, T3: IdentifiableType,
    T4: IdentifiableType, T5: IdentifiableType, T6: IdentifiableType,
    T7: IdentifiableType, T8: IdentifiableType, T9: IdentifiableType
{
    public static func validate(runtime: Runtime,
                                type: NetworkType.Info) -> Result<Void, TypeError>
    {
        definition.validate(runtime: runtime, type: type.type)
    }
}

extension Tuple10: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType, T3: IdentifiableType,
    T4: IdentifiableType, T5: IdentifiableType, T6: IdentifiableType,
    T7: IdentifiableType, T8: IdentifiableType, T9: IdentifiableType,
    T10: IdentifiableType
{
    public static func validate(runtime: Runtime,
                                type: NetworkType.Info) -> Result<Void, TypeError>
    {
        definition.validate(runtime: runtime, type: type.type)
    }
}

extension Tuple11: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType, T3: IdentifiableType,
    T4: IdentifiableType, T5: IdentifiableType, T6: IdentifiableType,
    T7: IdentifiableType, T8: IdentifiableType, T9: IdentifiableType,
    T10: IdentifiableType, T11: IdentifiableType
{
    public static func validate(runtime: Runtime,
                                type: NetworkType.Info) -> Result<Void, TypeError>
    {
        definition.validate(runtime: runtime, type: type.type)
    }
}

extension Tuple12: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType, T3: IdentifiableType,
    T4: IdentifiableType, T5: IdentifiableType, T6: IdentifiableType,
    T7: IdentifiableType, T8: IdentifiableType, T9: IdentifiableType,
    T10: IdentifiableType, T11: IdentifiableType, T12: IdentifiableType
{
    public static func validate(runtime: Runtime,
                                type: NetworkType.Info) -> Result<Void, TypeError>
    {
        definition.validate(runtime: runtime, type: type.type)
    }
}

extension Tuple13: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType, T3: IdentifiableType,
    T4: IdentifiableType, T5: IdentifiableType, T6: IdentifiableType,
    T7: IdentifiableType, T8: IdentifiableType, T9: IdentifiableType,
    T10: IdentifiableType, T11: IdentifiableType, T12: IdentifiableType,
    T13: IdentifiableType
{
    public static func validate(runtime: Runtime,
                                type: NetworkType.Info) -> Result<Void, TypeError>
    {
        definition.validate(runtime: runtime, type: type.type)
    }
}

extension Tuple14: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType, T3: IdentifiableType,
    T4: IdentifiableType, T5: IdentifiableType, T6: IdentifiableType,
    T7: IdentifiableType, T8: IdentifiableType, T9: IdentifiableType,
    T10: IdentifiableType, T11: IdentifiableType, T12: IdentifiableType,
    T13: IdentifiableType, T14: IdentifiableType
{
    public static func validate(runtime: Runtime,
                                type: NetworkType.Info) -> Result<Void, TypeError>
    {
        definition.validate(runtime: runtime, type: type.type)
    }
}

extension Tuple15: IdentifiableTuple, IdentifiableType where
    T1: IdentifiableType, T2: IdentifiableType, T3: IdentifiableType,
    T4: IdentifiableType, T5: IdentifiableType, T6: IdentifiableType,
    T7: IdentifiableType, T8: IdentifiableType, T9: IdentifiableType,
    T10: IdentifiableType, T11: IdentifiableType, T12: IdentifiableType,
    T13: IdentifiableType, T14: IdentifiableType, T15: IdentifiableType
{
    public static func validate(runtime: Runtime,
                                type: NetworkType.Info) -> Result<Void, TypeError>
    {
        definition.validate(runtime: runtime, type: type.type)
    }
}
