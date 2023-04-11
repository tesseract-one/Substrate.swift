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

public protocol OpaqueExtrinsic: Decodable {
    func decode() throws -> Extrinsic<DynamicCall<RuntimeTypeId>, Value<RuntimeTypeId>>
    
    static var version: UInt8 { get }
}

public protocol StaticOpaqueExtrinsic: OpaqueExtrinsic {
    associatedtype TManager: ExtrinsicManager
    
    func decode<C: Call & ScaleRuntimeDecodable>() throws -> Extrinsic<C, TManager.TSignedExtra>
}

public enum ExtrinsicCodingError: Error {
    case badExtraType(expected: String, got: String)
    case badExtrinsicVersion(supported: UInt8, got: UInt8)
    case badExtrasCount(expected: Int, got: Int)
    case valueNotFound(key: String)
    case unknownExtension(identifier: String)
    case unsupportedSubstrate(reason: String)
}

public protocol ExtrinsicDecoder {
    var version: UInt8 { get }
    
    func decode(dynamic decoder: ScaleDecoder) throws -> Extrinsic<DynamicCall<RuntimeTypeId>, Value<RuntimeTypeId>>
    func decode<C: Call & ScaleRuntimeDecodable, E>(static decoder: ScaleDecoder) throws -> Extrinsic<C, E>
    
    static var version: UInt8 { get }
}

public extension ExtrinsicDecoder {
    var version: UInt8 { Self.version }
}

public typealias SignedExtrinsic<C: Call, M: ExtrinsicManager> = Extrinsic<C, M.TSignedExtra>
public typealias UnsignedExtrinsic<C: Call, M: ExtrinsicManager> = Extrinsic<C, M.TUnsignedExtra>

public protocol ExtrinsicManager<RT>: ExtrinsicDecoder {
    associatedtype RT: System
    associatedtype TUnsignedParams
    associatedtype TSigningParams
    associatedtype TUnsignedExtra
    associatedtype TSigningExtra
    associatedtype TSignedExtra
    
    func build<C: Call>(
        unsigned call: C, params: TUnsignedParams
    ) async throws -> Extrinsic<C, TUnsignedExtra>
    func encode<C: Call>(unsigned extrinsic: Extrinsic<C, TUnsignedExtra>, in encoder: ScaleEncoder) throws
    
    func build<C: Call>(
        payload extrinsic: Extrinsic<C, TUnsignedExtra>,
        params: TSigningParams
    ) async throws -> ExtrinsicSignPayload<C, TSigningExtra>
    func encode<C: Call>(payload: ExtrinsicSignPayload<C, TSigningExtra>, in encoder: ScaleEncoder) throws
    func decode<C: Call & ScaleRuntimeDecodable>(
        payload decoder: ScaleDecoder
    ) throws -> ExtrinsicSignPayload<C, TSigningExtra>
    
    func build<C: Call>(signed payload: ExtrinsicSignPayload<C, TSigningExtra>,
                        address: RT.TAddress,
                        signature: RT.TSignature) throws -> Extrinsic<C, TSignedExtra>
    func encode<C: Call>(signed extrinsic: Extrinsic<C, TSignedExtra>, in encoder: ScaleEncoder) throws
    
    mutating func setSubstrate<S: AnySubstrate<RT>>(substrate: S) throws
}

public struct DynamicExtrinsicExtensionKey: Equatable, Hashable, RawRepresentable {
    public typealias RawValue = String
    public var rawValue: String
    public init(_ string: String) {
        self.rawValue = string
    }
    public init?(rawValue: String) {
        self.init(rawValue)
    }
}

public protocol DynamicExtrinsicExtension {
    var identifier: String { get }
    
    func extra<S: AnySubstrate>(
        substrate: S, params: [DynamicExtrinsicExtensionKey: Value<Void>]
    ) async throws -> Value<Void>
    
    func additionalSigned<S: AnySubstrate>(
        substrate: S, params: [DynamicExtrinsicExtensionKey: Value<Void>]
    ) async throws -> Value<Void>
}

public struct BlockExtrinsic<S: System>: StaticOpaqueExtrinsic {
    public typealias TManager = S.TExtrinsicManager
    
    public let data: Data
    public let runtime: any Runtime
    
    public init(from decoder: Decoder) throws {
        self.runtime = decoder.runtime
        let container = try decoder.singleValueContainer()
        self.data = try container.decode(Data.self)
    }
    
    public func decode() throws -> Extrinsic<DynamicCall<RuntimeTypeId>, Value<RuntimeTypeId>> {
        try runtime.extrinsicDecoder.decode(dynamic: runtime.decoder(with: data))
    }
    
    public func decode<C: Call & ScaleRuntimeDecodable>() throws -> Extrinsic<C, TManager.TSignedExtra> {
        try runtime.extrinsicDecoder.decode(static: runtime.decoder(with: data))
    }
    
    public static var version: UInt8 { TManager.version }
}
