//
//  RuntimeMetadataV15.swift
//  
//
//  Created by Yehor Popovych on 24.04.2023
//

import Foundation
import ScaleCodec

public class RuntimeMetadataV15: RuntimeMetadataV14 {
    public override var version: UInt8 { 15 }
    public private(set) var apis: [RuntimeRuntimeApiMetadataV15]!
    
    public required init(from decoder: ScaleDecoder) throws {
        try super.init(from: decoder)
        apis = try decoder.decode()
    }
    
    public override func encode(in encoder: ScaleEncoder) throws {
        try super.encode(in: encoder)
        try encoder.encode(apis)
    }
    
    public override func asMetadata() -> Metadata {
        MetadataV15(runtime: self)
    }
    
    public override class var versions: Set<UInt32> { [15, UInt32.max] }
}

public struct RuntimeRuntimeApiMetadataV15: ScaleCodable {
    public let name: String
    public let methods: [RuntimeRuntimeApiMethodMetadataV15]
    public let docs: [String]
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        methods = try decoder.decode()
        docs = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(name).encode(methods).encode(docs)
    }
}

public struct RuntimeRuntimeApiMethodMetadataV15: ScaleCodable {
    public let name: String
    public let inputs: [RuntimeRuntimeApiMethodParamMetadataV15]
    public let output: RuntimeTypeId
    public let docs: [String]
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        inputs = try decoder.decode()
        output = try decoder.decode()
        docs = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(name).encode(inputs)
                .encode(output).encode(docs)
    }
}

public struct RuntimeRuntimeApiMethodParamMetadataV15: ScaleCodable {
    public let name: String
    public let type: RuntimeTypeId
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        type = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(name).encode(type)
    }
}
