//
//  Types+Identifiable.swift
//  
//
//  Created by Yehor Popovych on 02/09/2023.
//

import Foundation
import ScaleCodec
import Numberick

public extension CaseIterable where Self: IdentifiableTypeStatic {
    @inlinable
    static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
        .variant(variants: allCases.enumerated().map { (idx, cs) in
            .e(UInt8(idx), String(describing: cs).uppercasedFirst)
        })
    }
}

extension UInt8: IdentifiableTypeStatic {
    @inlinable
    public static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
        .primitive(is: .u8)
    }
}
extension UInt16: IdentifiableTypeStatic {
    @inlinable
    public static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
        .primitive(is: .u16)
    }
}
extension UInt32: IdentifiableTypeStatic {
    @inlinable
    public static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
        .primitive(is: .u32)
    }
}
extension UInt64: IdentifiableTypeStatic {
    @inlinable
    public static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
        .primitive(is: .u64)
    }
}
extension UInt: IdentifiableTypeStatic {
    @inlinable
    public static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
        MemoryLayout<UInt>.size == 4 ? .primitive(is: .u32) : .primitive(is: .u64)
    }
}
extension NBKDoubleWidth: IdentifiableTypeStatic {
    @inlinable
    public static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
        switch bitWidth {
        case 128: return isSigned ? .primitive(is: .i128) : .primitive(is: .u128)
        case 256: return isSigned ? .primitive(is: .i256) : .primitive(is: .u256)
        default: preconditionFailure("Bad big integer size: \(bitWidth)")
        }
    }
}
extension Int8: IdentifiableTypeStatic {
    @inlinable
    public static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder{
        .primitive(is: .i8)
    }
}
extension Int16: IdentifiableTypeStatic {
    @inlinable
    public static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
        .primitive(is: .i16)
    }
}
extension Int32: IdentifiableTypeStatic {
    @inlinable
    public static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
        .primitive(is: .i32)
    }
}
extension Int64: IdentifiableTypeStatic {
    @inlinable
    public static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
        .primitive(is: .i64)
    }
}
extension Int: IdentifiableTypeStatic {
    @inlinable
    public static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
        MemoryLayout<UInt>.size == 4 ? .primitive(is: .i32) : .primitive(is: .i64)
    }
}
extension Bool: IdentifiableTypeStatic {
    @inlinable
    public static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
        .primitive(is: .bool)
    }
}

extension String: IdentifiableTypeStatic {
    @inlinable
    public static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
        .primitive(is: .str)
    }
}

extension Compact: IdentifiableTypeStatic where T: IdentifiableTypeStatic {
    @inlinable
    public static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
        .compact(of: registry.def(T.self))
    }
}

extension Character: IdentifiableTypeStatic {
    @inlinable
    public static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
        .primitive(is: .char)
    }
}

public extension Collection where Self: IdentifiableTypeCustomWrapperStatic,
                                  TypeConfig == IdentifiableCollectionTypeConfig
{
    @inlinable
    static func definition(
        in registry: TypeRegistry<TypeDefinition.TypeId>,
        config: TypeConfig, wrapped: TypeDefinition
    ) -> TypeDefinition.Builder {
        switch config {
        case .dynamic: return .sequence(of: wrapped)
        case .fixed(let count): return .array(count: count, of: wrapped)
        }
    }
}

public extension Collection where Self: IdentifiableWithConfigTypeStatic,
                                  Self: IdentifiableTypeCustomWrapperStatic,
                                  TypeConfig == IdentifiableCollectionTypeConfig,
                                  Element: IdentifiableTypeStatic
{
    @inlinable
    static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>,
                           _ config: TypeConfig) -> TypeDefinition.Builder
    {
        definition(in: registry, config: config, wrapped: registry.def(Element.self))
    }
}

extension Array: IdentifiableTypeCustomWrapperStatic {
    public typealias TypeConfig = IdentifiableCollectionTypeConfig
}

extension Array: IdentifiableWithConfigTypeStatic,
                 IdentifiableTypeStatic where Element: IdentifiableTypeStatic {}

extension Data: IdentifiableWithConfigTypeStatic, IdentifiableTypeCustomWrapperStatic, IdentifiableTypeStatic {
    public typealias TypeConfig = IdentifiableCollectionTypeConfig
}

extension Optional: IdentifiableTypeStatic where Wrapped: IdentifiableTypeStatic {
    @inlinable
    public static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder {
        definition(in: registry, config: .nothing, wrapped: registry.def(Wrapped.self))
    }
}

extension Optional: IdentifiableTypeCustomWrapperStatic {
    public typealias TypeConfig = Nothing
    
    public static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>,
                                  config: TypeConfig, wrapped: TypeDefinition) -> TypeDefinition.Builder
    {
        .variant(variants: [.e(0, "None"), .s(1, "Some", wrapped)])
    }
}

extension Either: IdentifiableTypeStatic where Left: IdentifiableTypeStatic,
                                               Right: IdentifiableTypeStatic
{
    @inlinable
    public static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> TypeDefinition.Builder
    {
        .variant(variants: [
            .s(0, "Ok", registry.def(Right.self)),
            .s(1, "Err", registry.def(Left.self))
        ])
    }
}
