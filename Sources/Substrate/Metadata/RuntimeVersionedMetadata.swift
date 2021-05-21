//
//  RuntimeMetadata.swift
//  
//
//  Created by Yehor Popovych on 12/2/20.
//

import Foundation
import ScaleCodec
#if !COCOAPODS
import SubstratePrimitives
#endif

public struct RuntimeVersionedMetadata: ScaleDecodable {
    public let magicNumber: UInt32
    public let metadata: RuntimeMetadata
    
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
        case 12:
            metadata = try decoder.decode(RuntimeMetadataV12.self)
        default: throw SDecodingError.dataCorrupted(
            SDecodingError.Context(
                path: decoder.path,
                description: "Unsupported metadata version \(version)"))
        }
    }
    
    public static let magickNumber: UInt32 = 0x6174656d
}
