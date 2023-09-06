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
    static var definition: TypeDefinition {
        .variant(variants: allCases.enumerated().map { (idx, cs) in
            .e(UInt8(idx), String(describing: cs).uppercasedFirst)
        })
    }
}

extension UInt8: IdentifiableTypeStatic {
    @inlinable
    public static var definition: TypeDefinition { .primitive(is: .u8) }
}
extension UInt16: IdentifiableTypeStatic {
    @inlinable
    public static var definition: TypeDefinition { .primitive(is: .u16) }
}
extension UInt32: IdentifiableTypeStatic {
    @inlinable
    public static var definition: TypeDefinition { .primitive(is: .u32) }
}
extension UInt64: IdentifiableTypeStatic {
    @inlinable
    public static var definition: TypeDefinition { .primitive(is: .u64) }
}
extension UInt: IdentifiableTypeStatic {
    @inlinable
    public static var definition: TypeDefinition {
        MemoryLayout<UInt>.size == 4 ? .primitive(is: .u32) : .primitive(is: .u64)
    }
}
extension NBKDoubleWidth: IdentifiableTypeStatic {
    @inlinable
    public static var definition: TypeDefinition {
        switch bitWidth {
        case 128: return isSigned ? .primitive(is: .i128) : .primitive(is: .u128)
        case 256: return isSigned ? .primitive(is: .i256) : .primitive(is: .u256)
        default: preconditionFailure("Bad big integer size: \(bitWidth)")
        }
    }
}
extension Int8: IdentifiableTypeStatic {
    @inlinable
    public static var definition: TypeDefinition { .primitive(is: .i8) }
}
extension Int16: IdentifiableTypeStatic {
    @inlinable
    public static var definition: TypeDefinition { .primitive(is: .i16) }
}
extension Int32: IdentifiableTypeStatic {
    @inlinable
    public static var definition: TypeDefinition { .primitive(is: .i32) }
}
extension Int64: IdentifiableTypeStatic {
    @inlinable
    public static var definition: TypeDefinition { .primitive(is: .i64) }
}
extension Int: IdentifiableTypeStatic {
    @inlinable
    public static var definition: TypeDefinition {
        MemoryLayout<UInt>.size == 4 ? .primitive(is: .i32) : .primitive(is: .i64)
    }
}

extension Bool: IdentifiableTypeStatic {
    @inlinable
    public static var definition: TypeDefinition { .primitive(is: .bool) }
}

extension String: IdentifiableTypeStatic {
    @inlinable
    public static var definition: TypeDefinition { .primitive(is: .str) }
}

extension Data: IdentifiableTypeStatic {
    @inlinable
    public static var definition: TypeDefinition { .data }
}

extension Compact: IdentifiableTypeStatic where T: IdentifiableTypeStatic {
    @inlinable
    public static var definition: TypeDefinition {
        .compact(of: T.definition)
    }
}

extension Character: IdentifiableTypeStatic {
    @inlinable
    public static var definition: TypeDefinition { .primitive(is: .char) }
}

extension Array: IdentifiableTypeStatic where Element: IdentifiableTypeStatic {
    @inlinable
    public static var definition: TypeDefinition { .sequence(of: Element.definition) }
}

extension Optional: IdentifiableTypeStatic where Wrapped: IdentifiableTypeStatic {
    @inlinable
    public static var definition: TypeDefinition {
        .variant(variants: [.e(0, "None"), .s(1, "Some", Wrapped.definition)])
    }
}

extension Either: IdentifiableTypeStatic where Left: IdentifiableTypeStatic, Right: IdentifiableTypeStatic {
    @inlinable
    public static var definition: TypeDefinition {
        .variant(variants: [.s(0, "Ok", Right.definition),
                            .s(1, "Err", Left.definition)])
    }
}
