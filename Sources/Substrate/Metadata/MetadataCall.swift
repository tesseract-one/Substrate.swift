//
//  MetadataCall.swift
//  
//
//  Created by Yehor Popovych on 12/29/20.
//

import Foundation
import SubstratePrimitives

public class MetadataCallInfo {
    public let name: String
    public let arguments: [String]
    public let types: Dictionary<String, DType>
    public let documentation: String
    
    public var argumentsList: [(String, DType)] {
        arguments.map { ($0, self.types[$0]!) }
    }
    
    public init(runtime: RuntimeCallMetadata) throws {
        name = runtime.name
        documentation = runtime.documentation.joined(separator: "\n")
        arguments = runtime.arguments.map { $0.name }
        let typesList = try runtime.arguments.map { try ($0.name, DType(parse: $0.type)) }
        types = Dictionary(uniqueKeysWithValues: typesList)
    }
}