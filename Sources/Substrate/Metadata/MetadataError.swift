//
//  MetadataError.swift
//  
//
//  Created by Yehor Popovych on 12/29/20.
//

import Foundation
import SubstratePrimitives

public class MetadataDynamicError: Error {
    public let name: String
    public let description: String
    
    public init(runtime: RuntimeErrorMetadata) {
        name = runtime.name
        description = runtime.documentation.joined(separator: "\n")
    }
}
