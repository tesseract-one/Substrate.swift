//
//  MetadataRuntimeCalls.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec

public struct MetadataVersionsRuntimeCall: StaticCodableRuntimeCall {
    public typealias TReturn = [UInt32]
    public static let method = "metadata_versions"
    public static let api = "Metadata"
    
    public init() {}
    public func encodeParams<E: ScaleCodec.Encoder>(in encoder: inout E) throws {}
}

public struct MetadataAtVersionRuntimeCall: StaticCodableRuntimeCall{
    public typealias TReturn = Optional<OpaqueMetadata>
    public static let method = "metadata_at_version"
    public static let api = "Metadata"
    
    public let version: UInt32
    
    public init(version: UInt32) { self.version = version }
    public func encodeParams<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
        try encoder.encode(version)
    }
}
