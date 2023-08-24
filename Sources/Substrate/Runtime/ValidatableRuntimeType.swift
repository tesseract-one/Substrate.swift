//
//  ValidatableRuntimeType.swift
//  
//
//  Created by Yehor Popovych on 21/08/2023.
//

import Foundation
import ScaleCodec
import Numberick

public protocol ValidatableRuntimeType {
    static func validate(runtime: any Runtime, type id: RuntimeType.Id) -> Result<Void, TypeValidationError>
}

public enum TypeValidationError: Error {
    case typeNotFound(RuntimeType.Id)
    case wrongType(got: RuntimeType, for: String)
    case wrongValuesCount(in: RuntimeType, expected: Int, for: String)
    case variantNotFound(name: String, in: RuntimeType)
    case typeIdMismatch(got: RuntimeType.Id, has: RuntimeType.Id)
}

public extension FixedWidthInteger {
    static func validate(runtime: any Runtime,
                         type id: RuntimeType.Id) -> Result<Void, TypeValidationError>
    {
        guard let info = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(id))
        }
        guard let primitive = info.asPrimitive(runtime), let int = primitive.isAnyInt else {
            return .failure(.wrongType(got: info, for: String(describing: Self.self)))
        }
        guard int.signed == Self.isSigned, int.bits == Self.bitWidth else {
            return .failure(.wrongType(got: info, for: String(describing: Self.self)))
        }
        return .success(())
    }
}

extension UInt8: ValidatableRuntimeType {}
extension UInt16: ValidatableRuntimeType {}
extension UInt32: ValidatableRuntimeType {}
extension UInt64: ValidatableRuntimeType {}
extension UInt: ValidatableRuntimeType {}
extension NBKDoubleWidth: ValidatableRuntimeType {}
extension Int8: ValidatableRuntimeType {}
extension Int16: ValidatableRuntimeType {}
extension Int32: ValidatableRuntimeType {}
extension Int64: ValidatableRuntimeType {}
extension Int: ValidatableRuntimeType {}

extension Value: ValidatableRuntimeType {
    public static func validate(runtime: any Runtime,
                                type id: RuntimeType.Id) -> Result<Void, TypeValidationError>
    {
        return .success(())
    }
}

extension Bool: ValidatableRuntimeType {
    public static func validate(runtime: Runtime,
                                type id: RuntimeType.Id) -> Result<Void, TypeValidationError>
    {
        guard let info = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(id))
        }
        guard let primitive = info.asPrimitive(runtime), primitive.isBool else {
            return .failure(.wrongType(got: info, for: String(describing: Self.self)))
        }
        return .success(())
    }
}

extension String: ValidatableRuntimeType {
    public static func validate(runtime: Runtime,
                                type id: RuntimeType.Id) -> Result<Void, TypeValidationError>
    {
        guard let info = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(id))
        }
        guard let primitive = info.asPrimitive(runtime), primitive.isString else {
            return .failure(.wrongType(got: info, for: String(describing: Self.self)))
        }
        return .success(())
    }
}

extension Data: ValidatableRuntimeType {
    public static func validate(runtime: Runtime,
                                type id: RuntimeType.Id) -> Result<Void, TypeValidationError>
    {
        guard let info = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(id))
        }
        guard info.asBytes(runtime) != nil else {
            return .failure(.wrongType(got: info, for: String(describing: Self.self)))
        }
        return .success(())
    }
}

extension Compact: ValidatableRuntimeType {
    public static func validate(runtime: any Runtime,
                                type id: RuntimeType.Id) -> Result<Void, TypeValidationError>
    {
        guard let info = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(id))
        }
        guard let compact = info.asCompact(runtime) else {
            return .failure(.wrongType(got: info, for: String(describing: Self.self)))
        }
        guard let primitive = compact.asPrimitive(runtime), let bits = primitive.isUInt else {
            return .failure(.wrongType(got: info, for: String(describing: Self.self)))
        }
        guard bits <= T.compactBitWidth else {
            return .failure(.wrongType(got: info, for: String(describing: Self.self)))
        }
        return .success(())
    }
}

extension Character: ValidatableRuntimeType {
    public static func validate(runtime: Runtime,
                                type id: RuntimeType.Id) -> Result<Void, TypeValidationError>
    {
        guard let info = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(id))
        }
        guard let primitive = info.asPrimitive(runtime), primitive.isChar else {
            return .failure(.wrongType(got: info, for: String(describing: Self.self)))
        }
        return .success(())
    }
}

extension Array: ValidatableRuntimeType where Element: ValidatableRuntimeType {
    public static func validate(runtime: Runtime,
                                type id: RuntimeType.Id) -> Result<Void, TypeValidationError>
    {
        guard let info = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(id))
        }
        let flat = info.flatten(runtime)
        switch flat.definition {
        case .array(count: _, of: let eType), .sequence(of: let eType):
            return Element.validate(runtime: runtime, type: eType)
        case .composite(fields: let fields):
            for field in fields {
                switch Element.validate(runtime: runtime, type: field.type) {
                case .success(_): continue
                case .failure(let err): return .failure(err)
                }
            }
            return .success(())
        case .tuple(components: let ids):
            for id in ids {
                switch Element.validate(runtime: runtime, type: id) {
                case .success(_): continue
                case .failure(let err): return .failure(err)
                }
            }
            return .success(())
        default:
            return .failure(.wrongType(got: info, for: String(describing: Self.self)))
        }
    }
}

extension Optional: ValidatableRuntimeType where Wrapped: ValidatableRuntimeType {
    public static func validate(runtime: Runtime,
                                type id: RuntimeType.Id) -> Result<Void, TypeValidationError>
    {
        guard let info = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(id))
        }
        guard let field = info.asOptional(runtime) else {
            return .failure(.wrongType(got: info, for: String(describing: Self.self)))
        }
        return Wrapped.validate(runtime: runtime, type: field.type)
    }
}

extension Either: ValidatableRuntimeType where Left: ValidatableRuntimeType, Right: ValidatableRuntimeType {
    public static func validate(runtime: Runtime,
                                type id: RuntimeType.Id) -> Result<Void, TypeValidationError>
    {
        guard let info = runtime.resolve(type: id) else {
            return .failure(.typeNotFound(id))
        }
        guard let result = info.asResult(runtime) else {
            return .failure(.wrongType(got: info, for: String(describing: Self.self)))
        }
        return Left.validate(runtime: runtime, type: result.err.type).flatMap {
            Right.validate(runtime: runtime, type: result.ok.type)
        }
    }
}
