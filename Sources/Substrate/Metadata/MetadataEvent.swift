//
//  MetadataEvent.swift
//  
//
//  Created by Yehor Popovych on 12/29/20.
//

import Foundation
import SubstratePrimitives

public class MetadataEventInfo {
    public let name: String
    public let arguments: [DType]
    public let documentation: String
    
    public init(runtime: RuntimeEventMetadata) throws {
        name = runtime.name
        documentation = runtime.documentation.joined(separator: "\n")
        arguments = try runtime.arguments.map { try DType(parse: $0) }
    }
}
