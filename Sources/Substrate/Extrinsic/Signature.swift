//
//  Signature.swift
//  
//
//  Created by Yehor Popovych on 18.04.2023.
//

import Foundation
import ScaleCodec

public protocol Signature: RuntimeDynamicCodable, ValueRepresentable,
                           ValidatableType, CustomStringConvertible
{
    var raw: Data { get }
    var algorithm: CryptoTypeId { get }
    
    init(raw: Data, algorithm: CryptoTypeId,
         runtime: any Runtime, type: TypeDefinition.Lazy) throws
    static func algorithms(runtime: any Runtime,
                           type: TypeDefinition.Lazy) throws -> [CryptoTypeId]
}

public extension Signature {
    @inlinable
    init(fake algorithm: CryptoTypeId, runtime: any Runtime,
         type: TypeDefinition.Lazy) throws
    {
        let sig = Data(repeating: 1, count: algorithm.signatureBytesCount)
        try self.init(raw: sig, algorithm: algorithm, runtime: runtime, type: type)
    }
    
    var description: String {
        "\(algorithm)(\(raw.hex()))"
    }
}

public protocol StaticSignature: Signature, RuntimeCodable {
    init(raw: Data, algorithm: CryptoTypeId, runtime: any Runtime) throws
    static func algorithms(runtime: any Runtime) throws -> [CryptoTypeId]
}

public extension StaticSignature {
    @inlinable
    init(raw: Data, algorithm: CryptoTypeId, runtime: any Runtime,
         type: TypeDefinition.Lazy) throws
    {
        try self.init(raw: raw, algorithm: algorithm, runtime: runtime)
    }
    
    @inlinable
    static func algorithms(runtime: any Runtime,
                           type: TypeDefinition.Lazy) throws -> [CryptoTypeId]
    {
        try Self.algorithms(runtime: runtime)
    }
}

public extension CryptoTypeId {
    var signatureBytesCount: Int {
        switch self {
        case .sr25519, .ed25519: return 64
        case .ecdsa: return 65
        }
    }
}
