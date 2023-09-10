//
//  MetadataRuntimeCalls.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec

public struct MetadataVersionsRuntimeCall: StaticCodableRuntimeCall, IdentifiableFrameType {
    public typealias TReturn = [UInt32]
    public static let method = "metadata_versions"
    public static let api = "Metadata"
    
    public init() {}
    public func encodeParams<E: ScaleCodec.Encoder>(in encoder: inout E) throws {}
    
    @inlinable
    public static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> FrameTypeDefinition {
        .runtimeCall(params: [], return: registry.def(TReturn.self, .dynamic))
    }
}

public struct MetadataAtVersionRuntimeCall: StaticCodableRuntimeCall, IdentifiableFrameType {
    public typealias TReturn = Optional<OpaqueMetadata>
    public static let method = "metadata_at_version"
    public static let api = "Metadata"
    
    public let version: UInt32
    
    public init(version: UInt32) { self.version = version }
    public func encodeParams<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
        try encoder.encode(version)
    }
    
    @inlinable
    public static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> FrameTypeDefinition {
        .runtimeCall(params: [.v(registry.def(UInt32.self))],
                     return: registry.def(TReturn.self))
    }
}
