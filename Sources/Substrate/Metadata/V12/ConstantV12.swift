//
//  File.swift
//  
//
//  Created by Yehor Popovych on 12/25/20.
//

import Foundation
import ScaleCodec

public struct ConstantMetadata: ScaleDecodable {
    public let name: String
    public let type: String
    public let value: Data
    public let documentation: [String]
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        type = try decoder.decode()
        value = try decoder.decode()
        documentation = try decoder.decode()
    }
}
