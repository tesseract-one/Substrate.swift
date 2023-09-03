//
//  Types+Validatable.swift
//  
//
//  Created by Yehor Popovych on 03/09/2023.
//

import Foundation
import ScaleCodec

extension Value: ValidatableType {
    @inlinable
    public static func validate(runtime: any Runtime,
                                type: NetworkType.Info) -> Result<Void, TypeError>
    {
        .success(())
    }
}

extension Data: ValidatableType {
    public static func validate(runtime: Runtime,
                                type: NetworkType.Info) -> Result<Void, TypeError>
    {
        guard type.type.asBytes(runtime) != nil else {
            return .failure(.wrongType(for: Self.self, got: type.type,
                                       reason: "Isn't byte array"))
        }
        return .success(())
    }
}

extension Compact: ValidatableType {
    public static func validate(runtime: any Runtime,
                                type: NetworkType.Info) -> Result<Void, TypeError>
    {
        guard let compact = type.type.asCompact(runtime) else {
            return .failure(.wrongType(for: Self.self, got: type.type,
                                       reason: "Isn't Compact"))
        }
        if let primitive = compact.asPrimitive(runtime) { // Compact<UInt>
            guard let bits = primitive.isUInt else {
                return .failure(.wrongType(for: Self.self, got: type.type,
                                           reason: "Type isn't UInt"))
            }
            guard bits <= T.compactBitWidth else {
                return .failure(.wrongType(for: Self.self, got: type.type,
                                           reason: "UInt\(bits) can't be stored in \(T.self)"))
            }
        } else if compact.isEmpty(runtime) { // Compact<()>
            guard T.compactBitWidth == 0 else {
                return .failure(.wrongType(for: Self.self, got: type.type,
                                           reason: "Compact<\(T.self)> != Compact<()>"))
            }
        } else { // Unknown Compact
            return .failure(.wrongType(for: Self.self, got: type.type,
                                       reason: "Unknown Compact"))
        }
        return .success(())
    }
}

extension Array: ValidatableType where Element: ValidatableType {
    public static func validate(runtime: Runtime,
                                type: NetworkType.Info) -> Result<Void, TypeError>
    {
        switch type.type.flatten(runtime).definition {
        case .array(count: _, of: let eType), .sequence(of: let eType):
            return Element.validate(runtime: runtime, type: eType).map{_ in}
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
            return .failure(.wrongType(for: Self.self, got: type.type,
                                       reason: "Isn't Array"))
        }
    }
}

extension Optional: ValidatableType where Wrapped: ValidatableType {
    public static func validate(runtime: Runtime,
                                type: NetworkType.Info) -> Result<Void, TypeError>
    {
        guard let field = type.type.asOptional(runtime) else {
            return .failure(.wrongType(for: Self.self, got: type.type,
                                       reason: "Isn't Optional"))
        }
        return Wrapped.validate(runtime: runtime, type: field.type).map{_ in}
    }
}

extension Either: ValidatableType where Left: ValidatableType, Right: ValidatableType {
    public static func validate(runtime: Runtime,
                                type: NetworkType.Info) -> Result<Void, TypeError>
    {
        guard let result = type.type.asResult(runtime) else {
            return .failure(.wrongType(for: Self.self, got: type.type,
                                       reason: "Isn't Result"))
        }
        return Left.validate(runtime: runtime, type: result.err.type).flatMap { _ in
            Right.validate(runtime: runtime, type: result.ok.type).map{_ in}
        }
    }
}
