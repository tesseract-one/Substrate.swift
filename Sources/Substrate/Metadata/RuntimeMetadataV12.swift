//
//  RuntimeMetadataV12.swift
//  
//
//  Created by Yehor Popovych on 12/29/20.
//

import Foundation
import ScaleCodec
import SubstratePrimitives

struct RuntimeMetadataV12: ScaleDecodable, RuntimeMetadata {
    var version: UInt8 { 12  }
    let modules: [RuntimeModuleMetadata]
    let extrinsic: RuntimeExtrinsicMetadata
    
    init(from decoder: ScaleDecoder) throws {
        modules = try decoder.decode([RuntimeModuleMetadataV12].self)
        extrinsic = try decoder.decode(RuntimeExtrinsicMetadataV4.self)
    }
}

struct RuntimeModuleMetadataV12: ScaleDecodable, RuntimeModuleMetadata {
    public let name: String
    public let storage: Optional<RuntimeStorageMetadata>
    public let calls: Optional<[RuntimeCallMetadata]>
    public let events: Optional<[RuntimeEventMetadata]>
    public let constants: [RuntimeConstantMetadata]
    public let errors: [RuntimeErrorMetadata]
    public let index: UInt8
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        storage = try decoder.decode(Optional<RuntimeStorageMetadataV12>.self)
        calls = try decoder.decode(Optional<[RuntimeCallMetadataV12]>.self)
        events = try decoder.decode(Optional<[RuntimeEventMetadataV12]>.self)
        constants = try decoder.decode([RuntimeConstantMetadataV12].self)
        errors = try decoder.decode([RuntimeErrorMetadataV12].self)
        index = try decoder.decode()
    }
}

struct RuntimeStorageItemMetadataV12: ScaleDecodable, RuntimeStorageItemMetadata {
    public let name: String
    public let modifier: StorageEntryModifier
    public let type: StorageEntryType
    public let defaultValue: Data
    public let documentation: [String]
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        modifier = try decoder.decode()
        type = try decoder.decode()
        defaultValue = try decoder.decode()
        documentation = try decoder.decode()
    }
}

struct RuntimeStorageMetadataV12: ScaleDecodable, RuntimeStorageMetadata {
    public let prefix: String
    public let items: [RuntimeStorageItemMetadata]
    
    public init(from decoder: ScaleDecoder) throws {
        prefix = try decoder.decode()
        items = try decoder.decode([RuntimeStorageItemMetadataV12].self)
    }
}

struct RuntimeCallArgumentsMetadataV12: ScaleDecodable, RuntimeCallArgumentsMetadata {
    public let name: String
    public let type: String
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        type = try decoder.decode()
    }
}

struct RuntimeCallMetadataV12: ScaleDecodable, RuntimeCallMetadata {
    public let name: String
    public let arguments: [RuntimeCallArgumentsMetadata]
    public let documentation: [String]
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        arguments = try decoder.decode([RuntimeCallArgumentsMetadataV12].self)
        documentation = try decoder.decode()
    }
}

struct RuntimeEventMetadataV12: ScaleDecodable, RuntimeEventMetadata {
    public let name: String
    public let arguments: [String]
    public let documentation: [String]
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        arguments = try decoder.decode()
        documentation = try decoder.decode()
    }
}

struct RuntimeConstantMetadataV12: ScaleDecodable, RuntimeConstantMetadata {
    public let name: String
    public let type: String
    public let value: Data
    public let documentation: [String]
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        type = try decoder.decode()
        value = try decoder.decode()
        documentation = try decoder.decode()
    }
}

struct RuntimeErrorMetadataV12: ScaleDecodable, RuntimeErrorMetadata {
    public let name: String
    public let documentation: [String]
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        documentation = try decoder.decode()
    }
}
