//
//  Extrinsic.swift
//  
//
//  Created by Yehor Popovych on 12.01.2023.
//

import Foundation
import ScaleCodec
import JsonRPC

public struct Extrinsic<C: Call, Extra> {
    public let call: C
    public let extra: Extra
    public let isSigned: Bool
    
    @inlinable
    public init(call: C, extra: Extra, signed: Bool) {
        self.call = call
        self.extra = extra
        self.isSigned = signed
    }
}

public struct ExtrinsicSignPayload<C: Call, Extra> {
    public let call: C
    public let extra: Extra
    
    @inlinable
    public init(call: C, extra: Extra) {
        self.call = call
        self.extra = extra
    }
}

public protocol OpaqueExtrinsic<TManager>: Decodable {
    associatedtype TManager: ExtrinsicManager
    
    func hash() -> TManager.RT.THasher.THash
    
    func decode<C: Call & ScaleRuntimeDecodable>() throws -> Extrinsic<C, TManager.TSignedExtra>
    
    static var version: UInt8 { get }
}

public enum ExtrinsicCodingError: Error {
    case badExtraType(expected: String, got: String)
    case badExtrinsicVersion(supported: UInt8, got: UInt8)
    case badExtrasCount(expected: Int, got: Int)
    case parameterNotFound(extension: ExtrinsicExtensionId, parameter: String)
    case unknownExtension(identifier: String)
    case unsupportedSubstrate(reason: String)
}

public typealias SignedExtrinsic<C: Call, M: ExtrinsicManager> = Extrinsic<C, M.TSignedExtra>
public typealias UnsignedExtrinsic<C: Call, M: ExtrinsicManager> = Extrinsic<C, M.TUnsignedExtra>
public typealias SigningPayload<C: Call, M: ExtrinsicManager> = ExtrinsicSignPayload<C, M.TSigningExtra>

public protocol ExtrinsicManager<RT> {
    associatedtype RT: System
    associatedtype TUnsignedParams
    associatedtype TSigningParams
    associatedtype TUnsignedExtra
    associatedtype TSigningExtra
    associatedtype TSignedExtra
    
    var version: UInt8 { get }
    
    func unsigned<C: Call>(call: C, params: TUnsignedParams) async throws -> Extrinsic<C, TUnsignedExtra>
    func encode<C: Call>(unsigned extrinsic: Extrinsic<C, TUnsignedExtra>, in encoder: ScaleEncoder) throws
    func decode<C: Call & ScaleRuntimeDecodable>(
        unsigned decoder: ScaleDecoder
    ) throws -> Extrinsic<C, TUnsignedExtra>
    
    func params<C: Call>(
        unsigned extrinsic: Extrinsic<C, TUnsignedExtra>,
        overrides: TSigningParams?
    ) async throws -> TSigningParams
    
    func payload<C: Call>(
        unsigned extrinsic: Extrinsic<C, TUnsignedExtra>,
        params: TSigningParams
    ) async throws -> ExtrinsicSignPayload<C, TSigningExtra>
    func encode<C: Call>(payload: ExtrinsicSignPayload<C, TSigningExtra>, in encoder: ScaleEncoder) throws
    func decode<C: Call & ScaleRuntimeDecodable>(
        payload decoder: ScaleDecoder
    ) throws -> ExtrinsicSignPayload<C, TSigningExtra>
    
    func signed<C: Call>(payload: ExtrinsicSignPayload<C, TSigningExtra>,
                         address: RT.TAddress,
                         signature: RT.TSignature) throws -> Extrinsic<C, TSignedExtra>
    func encode<C: Call>(signed extrinsic: Extrinsic<C, TSignedExtra>, in encoder: ScaleEncoder) throws
    func decode<C: Call & ScaleRuntimeDecodable>(signed decoder: ScaleDecoder) throws -> Extrinsic<C, TSignedExtra>
    
    mutating func setSubstrate<S: SomeSubstrate<RT>>(substrate: S) throws
    
    static var version: UInt8 { get }
    static func get(from runtime: any Runtime) throws -> Self
}

public extension ExtrinsicManager {
    var version: UInt8 { Self.version }
    
    static func get(from runtime: any Runtime) throws -> Self where RT: RuntimeConfig {
        guard let extended = runtime as? ExtendedRuntime<RT> else {
            throw ExtrinsicCodingError.unsupportedSubstrate(reason: "Runtime is not ER or different config")
        }
        guard let manager = extended.extrinsicManager as? Self else {
            throw ExtrinsicCodingError.unsupportedSubstrate(reason: "Different manager in runtime")
        }
        return manager
    }
}

public struct BlockExtrinsic<TManager: ExtrinsicManager>: OpaqueExtrinsic where TManager.RT: RuntimeConfig {
    public typealias TManager = TManager
    
    public let data: Data
    public let runtime: any Runtime
    
    public init(from decoder: Decoder) throws {
        self.runtime = decoder.runtime
        let container = try decoder.singleValueContainer()
        self.data = try container.decode(Data.self)
    }
    
    public func hash() -> TManager.RT.THasher.THash {
        try! TManager.RT.THasher.THash(runtime.hasher.hash(data: data))
    }
    
    public func decode<C: Call & ScaleRuntimeDecodable>() throws -> Extrinsic<C, TManager.TSignedExtra> {
        try TManager.get(from: runtime).decode(signed: runtime.decoder(with: data))
    }
    
    public static var version: UInt8 { TManager.version }
}
