//
//  Metadata.swift
//  
//
//  Created by Yehor Popovych on 12/2/20.
//

import Foundation
import SubstratePrimitives
import ScaleCodec

public struct Metadata: ScaleDecodable {
    public let magicNumber: UInt32
    public let metadata: SubstratePrimitives.Metadata
    
    public init(from decoder: ScaleDecoder) throws {
        magicNumber = try decoder.decode()
        guard magicNumber == Metadata.magickNumber else {
            throw SDecodingError.dataCorrupted(
                SDecodingError.Context(
                    path: decoder.path,
                    description: "Wrong magick number: \(magicNumber)")
            )
        }
        let version = try decoder.decode(UInt8.self)
        switch version {
        case 12:
            metadata = try decoder.decode(MetadataV12.self)
        default: throw SDecodingError.dataCorrupted(
            SDecodingError.Context(
                path: decoder.path,
                description: "Unsupported metadata version \(version)"))
        }
    }
    
    public static let magickNumber: UInt32 = 0x6174656d
}
