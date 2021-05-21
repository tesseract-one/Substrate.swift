//
//  RuntimeExtrinsicMetadataV4.swift
//  
//
//  Created by Yehor Popovych on 12/29/20.
//

import Foundation
import ScaleCodec
#if !COCOAPODS
import SubstratePrimitives
#endif

public struct RuntimeExtrinsicMetadataV4: ScaleDecodable, RuntimeExtrinsicMetadata, Encodable {
    public let version: UInt8
    public let signedExtensions: [String]
    
    public init(from decoder: ScaleDecoder) throws {
        version = try decoder.decode()
        signedExtensions = try decoder.decode()
    }
}
