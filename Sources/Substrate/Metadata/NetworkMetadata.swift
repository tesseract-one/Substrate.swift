//
//  RuntimeMetadata.swift
//  
//
//  Created by Yehor Popovych on 12/2/20.
//

import Foundation
import ScaleCodec

public protocol NetworkMetadata: ScaleCodec.Codable {
    var version: UInt8 { get }
    
    func asMetadata() throws -> Metadata
    
    static var versions: Set<UInt32> { get }
}

public struct VersionedNetworkMetadata: ScaleCodec.Codable, RuntimeDecodable {
    public let magicNumber: UInt32
    public let metadata: NetworkMetadata
    
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
            self.metadata = try decoder.decode(MetadataV14.Network.self)
        case 15:
            self.metadata = try decoder.decode(MetadataV15.Network.self)
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
        MetadataV14.Network.versions.union(MetadataV15.Network.versions)
    }()
    public static let magickNumber: UInt32 = 0x6174656d
}
