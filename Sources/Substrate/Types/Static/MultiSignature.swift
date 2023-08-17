//
//  MultiSignature.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec

public enum MultiSignature: Hashable, Equatable, CustomStringConvertible {
    case ed25519(Ed25519Signature)
    case sr25519(Sr25519Signature)
    case ecdsa(EcdsaSignature)
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
    public func asValue(runtime: Runtime, type: RuntimeType.Id) throws -> Value<RuntimeType.Id> {
        guard let info = runtime.resolve(type: type) else {
            throw ValueRepresentableError.typeNotFound(type)
        }
        let selfvars = Set(Self.supportedCryptoTypes.map{$0.signatureName})
        guard case .variant(variants: let variants) = info.definition.flatten(metadata: runtime.metadata) else {
            throw ValueRepresentableError.wrongType(got: info, for: "MultiSignature")
        }
        guard selfvars == Set(variants.map{$0.name}) else {
            throw ValueRepresentableError.wrongType(got: info, for: "MultiSignature")
        }
        let sig = self.signature
        guard let field = variants.first(where: {$0.name == sig.algorithm.signatureName})?.fields.first else {
            throw ValueRepresentableError.wrongType(got: info, for: "MultiSignature")
        }
        return try .variant(name: sig.algorithm.signatureName,
                            values: [sig.asValue(runtime: runtime, type: field.type)], type)
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
