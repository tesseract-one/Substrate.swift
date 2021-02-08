//
//  MetadataEvent.swift
//  
//
//  Created by Yehor Popovych on 12/29/20.
//

import Foundation
import SubstratePrimitives

public class MetadataEventInfo {
    public let index: UInt8
    public let name: String
    public let arguments: [DType]
    public let documentation: String
    
    public init(runtime: RuntimeEventMetadata, index: UInt8) throws {
        self.index = index
        name = runtime.name
        documentation = runtime.documentation.joined(separator: "\n")
        arguments = try runtime.arguments.map { try DType.fromMeta(type: $0) }
    }
}
