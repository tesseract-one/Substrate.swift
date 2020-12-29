//
//  MetadataCall.swift
//  
//
//  Created by Yehor Popovych on 12/29/20.
//

import Foundation
import SubstratePrimitives

public class MetadataCall {
    public let name: String
    public let arguments: [String]
    public let types: Dictionary<String, SType>
    public let documentation: String
    
    public var argumentsList: [(String, SType)] {
        arguments.map { ($0, self.types[$0]!) }
    }
    
    public init(runtime: RuntimeCallMetadata) throws {
        name = runtime.name
        documentation = runtime.documentation.joined(separator: "\n")
        arguments = runtime.arguments.map { $0.name }
        let typesList = try runtime.arguments.map { try ($0.name, SType($0.type)) }
        types = Dictionary(uniqueKeysWithValues: typesList)
    }
}
