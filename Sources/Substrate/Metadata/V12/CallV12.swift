//
//  File.swift
//  
//
//  Created by Yehor Popovych on 12/25/20.
//

import Foundation
import ScaleCodec

public struct CallArgumentsMetadata: ScaleDecodable {
    public let name: String
    public let type: String
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        type = try decoder.decode()
    }
}

public struct CallMetadata: ScaleDecodable {
    public let name: String
    public let arguments: [CallArgumentsMetadata]
    public let documentation: [String]
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        arguments = try decoder.decode()
        documentation = try decoder.decode()
    }
}
