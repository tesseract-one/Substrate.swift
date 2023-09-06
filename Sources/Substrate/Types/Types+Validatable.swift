//
//  Types+Validatable.swift
//  
//
//  Created by Yehor Popovych on 03/09/2023.
//

import Foundation
import ScaleCodec

public extension FixedWidthInteger {
    func validateInteger(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        let primitive: NetworkType.Primitive
        if let compact = info.type.asCompact(runtime) {
            guard let prim = compact.asPrimitive(runtime) else {
                return .failure(.wrongType(for: Self.self, got: info.type,
                                           reason: "Isn't compact primitive"))
            }
            primitive = prim
        } else {
            guard let prim = info.type.asPrimitive(runtime) else {
                return .failure(.wrongType(for: Self.self, got: info.type,
                                                    reason: "Isn't primitive"))
            }
            primitive = prim
        }
        switch primitive {
        case .u8: return validate(type: info.type, UInt8.self)
        case .u16: return validate(type: info.type, UInt16.self)
        case .u32: return validate(type: info.type, UInt32.self)
        case .u64: return validate(type: info.type, UInt64.self)
        case .u128: return validate(type: info.type, UInt128.self)
        case .u256: return validate(type: info.type, UInt256.self)
        case .i8: return validate(type: info.type, Int8.self)
        case .i16: return validate(type: info.type, Int16.self)
        case .i32: return validate(type: info.type, Int32.self)
        case .i64: return validate(type: info.type, Int64.self)
        case .i128: return validate(type: info.type, Int128.self)
        case .i256: return validate(type: info.type, Int256.self)
        default: return .failure(.wrongType(for: Self.self, got: info.type,
                                            reason: "Isn't integer"))
        }
    }
    
    private func validate<T: FixedWidthInteger>(type: NetworkType,
                                                _: T.Type) -> Result<Void, TypeError>
    {
        T(exactly: self) != nil
        ? .success(())
        : .failure(.wrongType(for: Self.self, got: type, reason: "Integer overflow"))
    }
}

extension UInt8: ValidatableTypeDynamic {
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        validateInteger(runtime: runtime, type: info)
    }
}
extension UInt16: ValidatableTypeDynamic {
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        validateInteger(runtime: runtime, type: info)
    }
}
extension UInt32: ValidatableTypeDynamic {
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        validateInteger(runtime: runtime, type: info)
    }
}
extension UInt64: ValidatableTypeDynamic {
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        validateInteger(runtime: runtime, type: info)
    }
}
extension UInt: ValidatableTypeDynamic {
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        validateInteger(runtime: runtime, type: info)
    }
}
extension Int8: ValidatableTypeDynamic {
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        validateInteger(runtime: runtime, type: info)
    }
}
extension Int16: ValidatableTypeDynamic {
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        validateInteger(runtime: runtime, type: info)
    }
}
extension Int32: ValidatableTypeDynamic {
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        validateInteger(runtime: runtime, type: info)
    }
}
extension Int64: ValidatableTypeDynamic {
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        validateInteger(runtime: runtime, type: info)
    }
}
extension Int: ValidatableTypeDynamic {
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        validateInteger(runtime: runtime, type: info)
    }
}
extension NBKDoubleWidth: ValidatableTypeDynamic {
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError> {
        validateInteger(runtime: runtime, type: info)
    }
}

extension Data: ValidatableTypeDynamic {
    public func validate(runtime: Runtime,
                         type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        guard let count = info.type.asBytes(runtime) else {
            return .failure(.wrongType(for: Self.self, got: info.type,
                                       reason: "Isn't bytes"))
        }
        guard count == 0 || self.count == count else {
            return .failure(.wrongValuesCount(for: Self.self, expected: self.count,
                                              in: info.type))
        }
        return .success(())
    }
}

extension Data: ValidatableTypeStatic {
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        guard info.type.asBytes(runtime) != nil else {
            return .failure(.wrongType(for: Self.self, got: info.type,
                                       reason: "Isn't byte array"))
        }
        return .success(())
    }
    
    public static func validate(count: UInt32, runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        guard let cnt = info.type.asBytes(runtime) else {
            return .failure(.wrongType(for: Self.self, got: info.type,
                                       reason: "Isn't byte array"))
        }
        guard count == cnt else {
            return .failure(.wrongValuesCount(for: Self.self, expected: Int(count),
                                              in: info.type))
        }
        return .success(())
    }
}

extension Compact: ValidatableTypeStatic {
    public static func validate(runtime: any Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        guard let compact = info.type.asCompact(runtime) else {
            return .failure(.wrongType(for: Self.self, got: info.type,
                                       reason: "Isn't Compact"))
        }
        if let primitive = compact.asPrimitive(runtime) { // Compact<UInt>
            guard let bits = primitive.isUInt else {
                return .failure(.wrongType(for: Self.self, got: info.type,
                                           reason: "Type isn't UInt"))
            }
            guard bits <= T.compactBitWidth else {
                return .failure(.wrongType(for: Self.self, got: info.type,
                                           reason: "UInt\(bits) can't be stored in \(T.self)"))
            }
        } else if compact.isEmpty(runtime) { // Compact<()>
            guard T.compactBitWidth == 0 else {
                return .failure(.wrongType(for: Self.self, got: info.type,
                                           reason: "Compact<\(T.self)> != Compact<()>"))
            }
        } else { // Unknown Compact
            return .failure(.wrongType(for: Self.self, got: info.type,
                                       reason: "Unknown Compact"))
        }
        return .success(())
    }
}

extension Array: ValidatableTypeStatic where Element: ValidatableTypeStatic {
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        switch info.type.flatten(runtime).definition {
        case .array(count: _, of: let eType), .sequence(of: let eType):
            return Element.validate(runtime: runtime, type: eType).map{_ in}
        case .composite(fields: let fields):
            return fields.voidErrorMap {
                Element.validate(runtime: runtime, type: $0.type).map {_ in}
            }
        case .tuple(components: let ids):
            return ids.voidErrorMap {
                Element.validate(runtime: runtime, type: $0).map {_ in}
            }
        default:
            return .failure(.wrongType(for: Self.self, got: info.type,
                                       reason: "Isn't Array"))
        }
    }
}

extension Optional: ValidatableTypeStatic where Wrapped: ValidatableTypeStatic {
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        guard let field = info.type.asOptional(runtime) else {
            return .failure(.wrongType(for: Self.self, got: info.type,
                                       reason: "Isn't Optional"))
        }
        return Wrapped.validate(runtime: runtime, type: field.type).map{_ in}
    }
}

extension Either: ValidatableTypeStatic where Left: ValidatableTypeStatic, Right: ValidatableTypeStatic {
    public static func validate(runtime: Runtime,
                                type info: NetworkType.Info) -> Result<Void, TypeError>
    {
        guard let result = info.type.asResult(runtime) else {
            return .failure(.wrongType(for: Self.self, got: info.type,
                                       reason: "Isn't Result"))
        }
        return Left.validate(runtime: runtime, type: result.err.type).flatMap { _ in
            Right.validate(runtime: runtime, type: result.ok.type).map{_ in}
        }
    }
}
