//
//  RuntimeMetadata.swift
//  
//
//  Created by Yehor Popovych on 12/2/20.
//

import Foundation
import ScaleCodec

public struct VersionedMetadata: ScaleCodec.Codable, RuntimeDecodable {
    public let magicNumber: UInt32
    public let metadata: RuntimeMetadata
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
        magicNumber = try decoder.decode()
        guard magicNumber == Self.magickNumber else {
            throw ScaleCodec.DecodingError.dataCorrupted(
                ScaleCodec.DecodingError.Context(
                    path: decoder.path,
                    description: "Wrong magick number: \(magicNumber)")
            )
        }
        let version = try decoder.decode(UInt8.self)
        switch version {
        case 14:
            self.metadata = try decoder.decode(RuntimeMetadataV14.self)
        case 15:
            self.metadata = try decoder.decode(RuntimeMetadataV15.self)
        default: throw ScaleCodec.DecodingError.dataCorrupted(
            ScaleCodec.DecodingError.Context(
                path: decoder.path,
                description: "Unsupported metadata version \(version)"))
        }
    }
    
    public func encode<E: ScaleCodec.Encoder>(in encoder: inout E) throws {
        try encoder.encode(magicNumber)
        try encoder.encode(metadata.version)
        try metadata.encode(in: &encoder)
    }
    
    public static let supportedVersions: Set<UInt32> = {
        RuntimeMetadataV14.versions.union(RuntimeMetadataV15.versions)
    }()
    public static let magickNumber: UInt32 = 0x6174656d
}
