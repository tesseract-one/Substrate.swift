//
//  Metadata.swift
//  
//
//  Created by Yehor Popovych on 12/2/20.
//

import Foundation
import Primitives
import ScaleCodec

public struct Metadata: ScaleDecodable {
    public let magicNumber: UInt32
    public let metadata: Primitives.Metadata
    
    public init(from decoder: ScaleDecoder) throws {
        magicNumber = try decoder.decode()
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
}
