//
//  File.swift
//  
//
//  Created by Yehor Popovych on 12/25/20.
//

import Foundation
import ScaleCodec

public struct ErrorMetadata: ScaleDecodable {
    public let name: String
    public let documentation: [String]
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        documentation = try decoder.decode()
    }
}
