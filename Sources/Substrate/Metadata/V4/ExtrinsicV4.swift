//
//  File.swift
//  
//
//  Created by Yehor Popovych on 12/25/20.
//

import Foundation
import ScaleCodec

public struct ExtrinsicMetadata: ScaleDecodable {
    public let version: UInt8
    public let signedExtensions: [String]
    
    public init(from decoder: ScaleDecoder) throws {
        version = try decoder.decode()
        signedExtensions = try decoder.decode()
    }
}
