//
//  RuntimeMetadata.swift
//  
//
//  Created by Yehor Popovych on 12/2/20.
//

import Foundation
import ScaleCodec

public struct VersionedMetadata: ScaleDecodable {
    public let magicNumber: UInt32
    public let metadata: Metadata
    
    public init(from decoder: ScaleDecoder) throws {
        magicNumber = try decoder.decode()
        guard magicNumber == Self.magickNumber else {
            throw SDecodingError.dataCorrupted(
                SDecodingError.Context(
                    path: decoder.path,
                    description: "Wrong magick number: \(magicNumber)")
            )
        }
        let version = try decoder.decode(UInt8.self)
        switch version {
        case 14:
            self.metadata = try decoder.decode(RuntimeMetadataV14.self).asMetadata()
        case 15:
            self.metadata = try decoder.decode(RuntimeMetadataV15.self).asMetadata()
        default: throw SDecodingError.dataCorrupted(
            SDecodingError.Context(
                path: decoder.path,
                description: "Unsupported metadata version \(version)"))
        }
    }
    
    public static let supportedVersions: Set<UInt32> = {
        RuntimeMetadataV14.versions.union(RuntimeMetadataV15.versions)
    }()
    public static let magickNumber: UInt32 = 0x6174656d
}
