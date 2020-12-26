//
//  ModuleV12.swift
//  
//
//  Created by Yehor Popovych on 12/25/20.
//

import Foundation
import ScaleCodec

public struct ModuleMetadata: ScaleDecodable {
    public let name: String
    public let storage: Optional<StorageMetadata>
    public let calls: Optional<[CallMetadata]>
    public let events: Optional<[EventMetadata]>
    public let constants: [ConstantMetadata]
    public let errors: [ErrorMetadata]
    public let index: UInt8
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        print("NAME", name)
        storage = try decoder.decode()
        calls = try decoder.decode()
        events = try decoder.decode()
        constants = try decoder.decode()
        errors = try decoder.decode()
        index = try decoder.decode()
    }
}
