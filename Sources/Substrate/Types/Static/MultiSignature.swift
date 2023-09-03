//
//  MultiSignature.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec

public enum MultiSignature: Hashable, Equatable, CustomStringConvertible,
                            VariantStaticValidatableType, IdentifiableType
{
    case ed25519(Ed25519Signature)
    case sr25519(Sr25519Signature)
    case ecdsa(EcdsaSignature)
    
    public static func validate(runtime: Runtime, type: NetworkType.Info) -> Result<Void, TypeError> {
        typeInfo(runtime: runtime, type: type).flatMap {
            validate(info: $0, type: type, runtime: runtime)
        }
    }
    
    public static var childTypes: ChildTypes {
        [(0, "Ed25519", [Ed25519Signature.self]), (1, "Sr25519", [Sr25519Signature.self]),
         (2, "Ecdsa", [EcdsaSignature.self])]
    }
    
    public static var definition: TypeDefinition {
        .variant(variants: [
            .s(0, "Ed25519", Ed25519Signature.definition),
            .s(1, "Sr25519", Sr25519Signature.definition),
            .s(2, "Ecdsa", EcdsaSignature.definition)
        ])
    }
}

extension MultiSignature: StaticSignature {
    public init(raw: Data, algorithm: CryptoTypeId, runtime: any Runtime) throws {
        switch algorithm {
        case .ecdsa:
            self = try .ecdsa(EcdsaSignature(decoding: raw))
        case .ed25519:
            self = try .ed25519(Ed25519Signature(decoding: raw))
        case .sr25519:
            self = try .sr25519(Sr25519Signature(decoding: raw))
        }
    }
    
    public var algorithm: CryptoTypeId {
        switch self {
        case .ed25519: return .ed25519
        case .ecdsa: return .ecdsa
        case .sr25519: return .sr25519
        }
    }
    
    public var raw: Data {
        switch self {
        case .ecdsa(let sig): return sig.raw
        case .sr25519(let sig): return sig.raw
        case .ed25519(let sig): return sig.raw
        }
    }
    
    public var signature: any Signature {
        switch self {
        case .ecdsa(let sig): return sig
        case .sr25519(let sig): return sig
        case .ed25519(let sig): return sig
        }
    }
    
    public static func algorithms(runtime: any Runtime) throws -> [CryptoTypeId] { Self.supportedCryptoTypes }
    public static let supportedCryptoTypes: [CryptoTypeId] = [.sr25519, .ecdsa, .ed25519]
}

extension MultiSignature: ValueRepresentable {
    public func asValue(runtime: Runtime, type: NetworkType.Id) throws -> Value<NetworkType.Id> {
        let info = try Self.validate(runtime: runtime, type: type).get()
        guard case .variant(variants: let variants) = info.type.flatten(runtime).definition else {
            throw TypeError.wrongType(for: Self.self, got: info.type, reason: "Should be variant")
        }
        switch self {
        case .sr25519(let sig):
            return try .variant(name: variants[0].name,
                                values: [sig.asValue(runtime: runtime, type: variants[0].fields[0].type)],
                                type)
        case .ed25519(let sig):
            return try .variant(name: variants[1].name,
                                values: [sig.asValue(runtime: runtime, type: variants[1].fields[0].type)],
                                type)
        case .ecdsa(let sig):
            return try .variant(name: variants[2].name,
                                values: [sig.asValue(runtime: runtime, type: variants[2].fields[0].type)],
                                type)
        }
    }
}

extension MultiSignature: ScaleCodec.Codable {
    public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
        let opt = try decoder.decode(.enumCaseId)
        switch opt {
        case 0: self = try .ed25519(decoder.decode())
        case 1: self = try .sr25519(decoder.decode())
        case 2: self = try .ecdsa(decoder.decode())
        default: throw decoder.enumCaseError(for: opt)
        }
    }
    
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
        switch self {
        case .ed25519(let s):
            try encoder.encode(0, .enumCaseId)
            try encoder.encode(s)
        case .sr25519(let s):
            try encoder.encode(1, .enumCaseId)
            try encoder.encode(s)
        case .ecdsa(let s):
            try encoder.encode(2, .enumCaseId)
            try encoder.encode(s)
        }
    }
}

extension MultiSignature: RuntimeCodable, RuntimeDynamicCodable {}
