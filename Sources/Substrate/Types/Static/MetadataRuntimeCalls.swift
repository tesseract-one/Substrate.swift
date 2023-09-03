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
    
    public static var definition: FrameTypeDefinition {
        .runtime(Self.self, params: [], return: TReturn.definition)
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
    
    public static var definition: FrameTypeDefinition {
        .runtime(Self.self, params: [.v(UInt32.definition)], return: TReturn.definition)
    }
}
