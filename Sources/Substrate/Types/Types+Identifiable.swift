//
//  Types+Identifiable.swift
//  
//
//  Created by Yehor Popovych on 02/09/2023.
//

import Foundation
import ScaleCodec
import Numberick

public extension CaseIterable where Self: IdentifiableType {
    @inlinable
    static var definition: TypeDefinition {
        .variant(variants: allCases.enumerated().map { (idx, cs) in
            .e(UInt8(idx), String(describing: cs).uppercasedFirst)
        })
    }
}

extension UInt8: IdentifiableType {
    @inlinable
    public static var definition: TypeDefinition { .primitive(is: .u8) }
}
extension UInt16: IdentifiableType {
    @inlinable
    public static var definition: TypeDefinition { .primitive(is: .u16) }
}
extension UInt32: IdentifiableType {
    @inlinable
    public static var definition: TypeDefinition { .primitive(is: .u32) }
}
extension UInt64: IdentifiableType {
    @inlinable
    public static var definition: TypeDefinition { .primitive(is: .u64) }
}
extension UInt: IdentifiableType {
    @inlinable
    public static var definition: TypeDefinition {
        MemoryLayout<UInt>.size == 4 ? .primitive(is: .u32) : .primitive(is: .u64)
    }
}
extension NBKDoubleWidth: IdentifiableType {
    @inlinable
    public static var definition: TypeDefinition {
        switch bitWidth {
        case 128: return isSigned ? .primitive(is: .i128) : .primitive(is: .u128)
        case 256: return isSigned ? .primitive(is: .i256) : .primitive(is: .u256)
        default: preconditionFailure("Bad big integer size: \(bitWidth)")
        }
    }
}
extension Int8: IdentifiableType {
    @inlinable
    public static var definition: TypeDefinition { .primitive(is: .i8) }
}
extension Int16: IdentifiableType {
    @inlinable
    public static var definition: TypeDefinition { .primitive(is: .i16) }
}
extension Int32: IdentifiableType {
    @inlinable
    public static var definition: TypeDefinition { .primitive(is: .i32) }
}
extension Int64: IdentifiableType {
    @inlinable
    public static var definition: TypeDefinition { .primitive(is: .i64) }
}
extension Int: IdentifiableType {
    @inlinable
    public static var definition: TypeDefinition {
        MemoryLayout<UInt>.size == 4 ? .primitive(is: .i32) : .primitive(is: .i64)
    }
}

extension Bool: IdentifiableType {
    @inlinable
    public static var definition: TypeDefinition { .primitive(is: .bool) }
}

extension String: IdentifiableType {
    @inlinable
    public static var definition: TypeDefinition { .primitive(is: .str) }
}

extension Data: IdentifiableType {
    @inlinable
    public static var definition: TypeDefinition { .data }
}

extension Compact: IdentifiableType where T: IdentifiableType {
    @inlinable
    public static var definition: TypeDefinition {
        .compact(of: T.definition)
    }
}

extension Character: IdentifiableType {
    @inlinable
    public static var definition: TypeDefinition { .primitive(is: .char) }
}

extension Array: IdentifiableType where Element: IdentifiableType {
    @inlinable
    public static var definition: TypeDefinition { .sequence(of: Element.definition) }
}

extension Optional: IdentifiableType where Wrapped: IdentifiableType {
    @inlinable
    public static var definition: TypeDefinition {
        .variant(variants: [.e(0, "None"), .s(1, "Some", Wrapped.definition)])
    }
}

extension Either: IdentifiableType where Left: IdentifiableType, Right: IdentifiableType {
    @inlinable
    public static var definition: TypeDefinition {
        .variant(variants: [.s(0, "Ok", Right.definition),
                            .s(1, "Err", Left.definition)])
    }
}
