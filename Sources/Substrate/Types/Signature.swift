//
//  Signature.swift
//  
//
//  Created by Yehor Popovych on 18.04.2023.
//

import Foundation
import ScaleCodec

public protocol Signature: ScaleRuntimeCodable {
    var raw: Data { get }
    var algorithm: CryptoTypeId { get }
    
    init(raw: Data, algorithm: CryptoTypeId, runtime: any Runtime) throws
    
    static func algorithms(runtime: any Runtime) throws -> [CryptoTypeId]
}

public extension Signature {
    init(fake algorithm: CryptoTypeId, runtime: any Runtime) throws {
        let sig = Data(repeating: 1, count: algorithm.signatureByteCount)
        try self.init(raw: sig, algorithm: algorithm, runtime: runtime)
    }
}

public extension CryptoTypeId {
    var signatureByteCount: Int {
        switch self {
        case .sr25519, .ed25519: return 64
        case .ecdsa: return 65
        }
    }
}

public struct AnySignature: Signature {
    public let raw: Data
    public let algorithm: CryptoTypeId
    
    public init(raw: Data, algorithm: CryptoTypeId, runtime: any Runtime) throws {
        self.raw = raw
        self.algorithm = algorithm
    }
    
    public init(from decoder: ScaleCodec.ScaleDecoder, runtime: Runtime) throws {
        try self.init(raw: Data(), algorithm: .sr25519, runtime: runtime)
    }
    
    public func encode(in encoder: ScaleCodec.ScaleEncoder, runtime: Runtime) throws {
    }
    
    public static func algorithms(runtime: any Runtime) throws -> [CryptoTypeId] {
        []
    }
}
