//
//  Extrinsic.swift
//  
//
//  Created by Yehor Popovych on 12.01.2023.
//

import Foundation
import ScaleCodec
import JsonRPC

public struct Extrinsic<C: Call, Extra: ExtrinsicExtra>: CustomStringConvertible {
    public let call: C
    public let extra: Extra
    
    @inlinable
    public var isSigned: Bool { extra.isSigned }
    
    @inlinable
    public init(call: C, extra: Extra) {
        self.call = call
        self.extra = extra
    }
    
    public var description: String {
        "\(isSigned ? "SignedExtrinsic" : "UnsignedExtrinsic")(call: \(call), extra: \(extra))"
    }
}

public protocol ExtrinsicExtra {
    var isSigned: Bool { get }
}

public struct ExtrinsicSignPayload<C: Call, Extra>: CustomStringConvertible {
    public let call: C
    public let extra: Extra
    
    @inlinable
    public init(call: C, extra: Extra) {
        self.call = call
        self.extra = extra
    }
    
    public var description: String {
        "ExtrinsicPayload(call: \(call), extra: \(extra))"
    }
}

extension Nothing: ExtrinsicExtra {
    public var isSigned: Bool { false }
}

extension Either: ExtrinsicExtra where Left: ExtrinsicExtra, Right: ExtrinsicExtra {
    public var isSigned: Bool {
        switch self {
        case .left(let l): return l.isSigned
        case .right(let r): return r.isSigned
        }
    }
}

public typealias AnyExtrinsic<C: Call, M: ExtrinsicManager> = Extrinsic<C, Either<M.TUnsignedExtra, M.TSignedExtra>>

public protocol OpaqueExtrinsic<TManager>: Decodable {
    associatedtype TManager: ExtrinsicManager
    
    func hash() -> TManager.RT.THasher.THash
    
    func decode<C: Call & ScaleRuntimeDecodable>() throws -> AnyExtrinsic<C, TManager>
    
    static var version: UInt8 { get }
}

public enum ExtrinsicCodingError: Error {
    case badExtrinsicVersion(supported: UInt8, got: UInt8)
    case badExtrasCount(expected: Int, got: Int)
    case parameterNotFound(extension: ExtrinsicExtensionId, parameter: String)
    case typeMismatch(expected: Any.Type, got: Any.Type)
    case unknownExtension(identifier: String)
    case unsupportedSubstrate(reason: String)
}

public typealias SignedExtrinsic<C: Call, M: ExtrinsicManager> = Extrinsic<C, M.TSignedExtra>
public typealias UnsignedExtrinsic<C: Call, M: ExtrinsicManager> = Extrinsic<C, M.TUnsignedExtra>
public typealias SigningPayload<C: Call, M: ExtrinsicManager> = ExtrinsicSignPayload<C, M.TSigningExtra>

public protocol ExtrinsicManager<RT> {
    associatedtype RT: Config
    associatedtype TUnsignedParams
    associatedtype TSigningParams
    associatedtype TUnsignedExtra: ExtrinsicExtra
    associatedtype TSigningExtra
    associatedtype TSignedExtra: ExtrinsicExtra
    
    var version: UInt8 { get }
    
    func unsigned<C: Call>(call: C, params: TUnsignedParams) async throws -> Extrinsic<C, TUnsignedExtra>
    func encode<C: Call>(unsigned extrinsic: Extrinsic<C, TUnsignedExtra>, in encoder: ScaleEncoder) throws
    
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
    
    func decode<C: Call & ScaleRuntimeDecodable>(from decoder: ScaleDecoder) throws -> AnyExtrinsic<C, Self>
    
    mutating func setSubstrate<S: SomeSubstrate<RT>>(substrate: S) throws
    
    static var version: UInt8 { get }
    static func get(from runtime: any Runtime) throws -> Self
}

public extension ExtrinsicManager {
    var version: UInt8 { Self.version }
    
    static func get(from runtime: any Runtime) throws -> Self where RT: Config {
        guard let extended = runtime as? ExtendedRuntime<RT> else {
            throw ExtrinsicCodingError.unsupportedSubstrate(reason: "Runtime is not ER or different config")
        }
        guard let manager = extended.extrinsicManager as? Self else {
            throw ExtrinsicCodingError.unsupportedSubstrate(reason: "Different manager in runtime")
        }
        return manager
    }    
}

public struct BlockExtrinsic<TManager: ExtrinsicManager>: OpaqueExtrinsic where TManager.RT: Config {
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
    
    public func decode<C: Call & ScaleRuntimeDecodable>() throws -> AnyExtrinsic<C, TManager> {
        try TManager.get(from: runtime).decode(from: runtime.decoder(with: data))
    }
    
    public static var version: UInt8 { TManager.version }
}
