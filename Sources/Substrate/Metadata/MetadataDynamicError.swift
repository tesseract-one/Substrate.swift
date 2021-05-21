//
//  MetadataError.swift
//  
//
//  Created by Yehor Popovych on 12/29/20.
//

import Foundation
#if !COCOAPODS
import SubstratePrimitives
#endif

public class MetadataDynamicError: Error {
    public let index: UInt8
    public let name: String
    public let description: String
    
    public init(runtime: RuntimeErrorMetadata, index: UInt8) {
        self.index = index
        name = runtime.name
        description = runtime.documentation.joined(separator: "\n")
    }
}
