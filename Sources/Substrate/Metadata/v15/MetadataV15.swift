//
//  MetadataV15.swift
//  
//
//  Created by Yehor Popovych on 24.04.2023.
//

import Foundation


public class MetadataV15: MetadataV14 {
    public private(set) var apisByName: [String: RuntimeApiMetadataV15]!
    public override var apis: [String] { Array(apisByName.keys) }
    
    public init(runtime: RuntimeMetadataV15) throws {
        try super.init(runtime: runtime)
        self.apisByName = Dictionary(
            uniqueKeysWithValues: runtime.apis.map {
                ($0.name, RuntimeApiMetadataV15(runtime: $0, types: types))
            }
        )
    }
    
    public override func resolve(api name: String) -> RuntimeApiMetadata? { apisByName[name] }
}

public struct RuntimeApiMetadataV15: RuntimeApiMetadata {
    public let runtime: RuntimeRuntimeApiMetadataV15
    public var name: String { runtime.name }
    public var methods: [String] { Array(methodsByName.keys) }
    
    public let methodsByName: [String: (params: [(String, RuntimeTypeInfo)], result: RuntimeTypeInfo)]
    
    public init(runtime: RuntimeRuntimeApiMetadataV15, types: [RuntimeTypeId: RuntimeType]) {
        self.runtime = runtime
        self.methodsByName = Dictionary(
            uniqueKeysWithValues: runtime.methods.map { method in
                let params = method.inputs.map {
                    ($0.name, RuntimeTypeInfo(id: $0.type, type: types[$0.type]!))
                }
                let result = RuntimeTypeInfo(id: method.output, type: types[method.output]!)
                return (method.name, (params, result))
            }
        )
    }
    
    public func resolve(method name: String) -> (params: [(String, RuntimeTypeInfo)], result: RuntimeTypeInfo)? {
        methodsByName[name]
    }
}
