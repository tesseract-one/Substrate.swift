//
//  Signature.swift
//  
//
//  Created by Yehor Popovych on 18.04.2023.
//

import Foundation
import ScaleCodec

public protocol Signature: ScaleRuntimeDynamicDecodable, ScaleRuntimeDynamicEncodable {
    var raw: Data { get }
    var algorithm: CryptoTypeId { get }
    
    init(raw: Data, algorithm: CryptoTypeId) throws
    
    static func algorithms(runtime: any Runtime) throws -> [CryptoTypeId]
}

public struct AnySignature: Signature {
    public let raw: Data
    public let algorithm: CryptoTypeId
    
    public init(raw: Data, algorithm: CryptoTypeId) throws {
        self.raw = raw
        self.algorithm = algorithm
    }
    
    public init(from decoder: ScaleCodec.ScaleDecoder, as type: RuntimeTypeId, runtime: Runtime) throws {
        try self.init(raw: Data(), algorithm: .sr25519)
    }
    
    public func encode(in encoder: ScaleCodec.ScaleEncoder, as type: RuntimeTypeId, runtime: Runtime) throws {
    }
    
    public static func algorithms(runtime: any Runtime) throws -> [CryptoTypeId] {
        []
    }
}
