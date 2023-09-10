//
//  Types+Validatable.swift
//  
//
//  Created by Yehor Popovych on 03/09/2023.
//

import Foundation
import ScaleCodec

public extension FixedWidthInteger {
    func validateInteger(type: TypeDefinition) -> Result<Void, TypeError>
    {
        let primitive: NetworkType.Primitive
        if let compact = type.asCompact() {
            guard let prim = compact.asPrimitive() else {
                return .failure(.wrongType(for: Self.self, type: type,
                                           reason: "Isn't compact primitive", .get()))
            }
            primitive = prim
        } else {
            guard let prim = type.asPrimitive() else {
                return .failure(.wrongType(for: Self.self, type: type,
                                           reason: "Isn't primitive", .get()))
            }
            primitive = prim
        }
        switch primitive {
        case .u8: return validate(type: type, UInt8.self)
        case .u16: return validate(type: type, UInt16.self)
        case .u32: return validate(type: type, UInt32.self)
        case .u64: return validate(type: type, UInt64.self)
        case .u128: return validate(type: type, UInt128.self)
        case .u256: return validate(type: type, UInt256.self)
        case .i8: return validate(type: type, Int8.self)
        case .i16: return validate(type: type, Int16.self)
        case .i32: return validate(type: type, Int32.self)
        case .i64: return validate(type: type, Int64.self)
        case .i128: return validate(type: type, Int128.self)
        case .i256: return validate(type: type, Int256.self)
        default: return .failure(.wrongType(for: Self.self, type: type,
                                            reason: "Isn't integer", .get()))
        }
    }
    
    private func validate<T: FixedWidthInteger>(type: TypeDefinition,
                                                _: T.Type) -> Result<Void, TypeError>
    {
        T(exactly: self) != nil
        ? .success(())
        : .failure(.wrongType(for: Self.self, type: type,
                              reason: "Integer overflow", .get()))
    }
}

extension UInt8: ValidatableTypeDynamic {
    public func validate(runtime: any Runtime,
                         type: TypeDefinition) -> Result<Void, TypeError> {
        validateInteger(type: type)
    }
}
extension UInt16: ValidatableTypeDynamic {
    public func validate(runtime: Runtime,
                         type: TypeDefinition) -> Result<Void, TypeError> {
        validateInteger(type: type)
    }
}
extension UInt32: ValidatableTypeDynamic {
    public func validate(runtime: Runtime,
                         type: TypeDefinition) -> Result<Void, TypeError> {
        validateInteger(type: type)
    }
}
extension UInt64: ValidatableTypeDynamic {
    public func validate(runtime: Runtime,
                         type: TypeDefinition) -> Result<Void, TypeError> {
        validateInteger(type: type)
    }
}
extension UInt: ValidatableTypeDynamic {
    public func validate(runtime: Runtime,
                         type: TypeDefinition) -> Result<Void, TypeError> {
        validateInteger(type: type)
    }
}
extension Int8: ValidatableTypeDynamic {
    public func validate(runtime: Runtime,
                         type: TypeDefinition) -> Result<Void, TypeError> {
        validateInteger(type: type)
    }
}
extension Int16: ValidatableTypeDynamic {
    public func validate(runtime: Runtime,
                         type: TypeDefinition) -> Result<Void, TypeError> {
        validateInteger(type: type)
    }
}
extension Int32: ValidatableTypeDynamic {
    public func validate(runtime: Runtime,
                         type: TypeDefinition) -> Result<Void, TypeError> {
        validateInteger(type: type)
    }
}
extension Int64: ValidatableTypeDynamic {
    public func validate(runtime: Runtime,
                         type: TypeDefinition) -> Result<Void, TypeError> {
        validateInteger(type: type)
    }
}
extension Int: ValidatableTypeDynamic {
    public func validate(runtime: Runtime,
                         type: TypeDefinition) -> Result<Void, TypeError> {
        validateInteger(type: type)
    }
}
extension NBKDoubleWidth: ValidatableTypeDynamic {
    public func validate(runtime: Runtime,
                         type: TypeDefinition) -> Result<Void, TypeError> {
        validateInteger(type: type)
    }
}

extension Data: ValidatableTypeDynamic {
    public func validate(runtime: Runtime,
                         type: TypeDefinition) -> Result<Void, TypeError>
    {
        guard let count = type.asBytes() else {
            return .failure(.wrongType(for: Self.self, type: type,
                                       reason: "Isn't bytes", .get()))
        }
        guard count == 0 || self.count == count else {
            return .failure(.wrongValuesCount(for: Self.self, expected: self.count,
                                              type: type, .get()))
        }
        return .success(())
    }
}

extension Data: ValidatableTypeStatic {
    public static func validate(type: TypeDefinition) -> Result<Void, TypeError>
    {
        guard type.asBytes() != nil else {
            return .failure(.wrongType(for: Self.self, type: type,
                                       reason: "Isn't byte array", .get()))
        }
        return .success(())
    }
    
    public static func validate(type: TypeDefinition,
                                count: UInt32) -> Result<Void, TypeError>
    {
        guard let cnt = type.asBytes() else {
            return .failure(.wrongType(for: Self.self, type: type,
                                       reason: "Isn't byte array", .get()))
        }
        guard count == cnt else {
            return .failure(.wrongValuesCount(for: Self.self, expected: Int(count),
                                              type: type, .get()))
        }
        return .success(())
    }
}

extension Compact: ValidatableTypeStatic {
    public static func validate(type: TypeDefinition) -> Result<Void, TypeError>
    {
        guard let compact = type.asCompact() else {
            return .failure(.wrongType(for: Self.self, type: type,
                                       reason: "Isn't Compact", .get()))
        }
        if let primitive = compact.asPrimitive() { // Compact<UInt>
            guard let bits = primitive.isUInt else {
                return .failure(.wrongType(for: Self.self, type: type,
                                           reason: "Type isn't UInt", .get()))
            }
            guard bits <= T.compactBitWidth else {
                return .failure(.wrongType(for: Self.self, type: type,
                                           reason: "UInt\(bits) can't be stored in \(T.self)",
                                           .get()))
            }
        } else if compact.isEmpty() { // Compact<()>
            guard T.compactBitWidth == 0 else {
                return .failure(.wrongType(for: Self.self, type: type,
                                           reason: "Compact<\(T.self)> != Compact<()>",
                                           .get()))
            }
        } else { // Unknown Compact
            return .failure(.wrongType(for: Self.self, type: type,
                                       reason: "Unknown Compact", .get()))
        }
        return .success(())
    }
}

extension Array: ValidatableTypeStatic where Element: ValidatableTypeStatic {
    public static func validate(type: TypeDefinition) -> Result<Void, TypeError>
    {
        switch type.flatten().definition {
        case .array(count: _, of: let eType), .sequence(of: let eType):
            return Element.validate(type: *eType)
        case .composite(fields: let fields):
            return fields.voidErrorMap {
                Element.validate(type: *$0.type)
            }
        default:
            return .failure(.wrongType(for: Self.self, type: type,
                                       reason: "Isn't Array", .get()))
        }
    }
}

extension Optional: ValidatableTypeStatic where Wrapped: ValidatableTypeStatic {
    public static func validate(type: TypeDefinition) -> Result<Void, TypeError>
    {
        guard let field = type.asOptional() else {
            return .failure(.wrongType(for: Self.self, type: type,
                                       reason: "Isn't Optional", .get()))
        }
        return Wrapped.validate(type: *field.type)
    }
}

extension Either: ValidatableTypeStatic where Left: ValidatableTypeStatic, Right: ValidatableTypeStatic {
    public static func validate(type: TypeDefinition) -> Result<Void, TypeError>
    {
        guard let result = type.asResult() else {
            return .failure(.wrongType(for: Self.self, type: type,
                                       reason: "Isn't Result", .get()))
        }
        return Left.validate(type: *result.err.type).flatMap { _ in
            Right.validate(type: *result.ok.type)
        }
    }
}
