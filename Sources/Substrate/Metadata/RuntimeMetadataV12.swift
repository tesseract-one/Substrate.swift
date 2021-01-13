//
//  RuntimeMetadataV12.swift
//  
//
//  Created by Yehor Popovych on 12/29/20.
//

import Foundation
import ScaleCodec
import SubstratePrimitives

struct RuntimeMetadataV12: ScaleDecodable, RuntimeMetadata, Encodable {
    var version: UInt8 { 12  }
    let modules: [RuntimeModuleMetadata]
    let extrinsic: RuntimeExtrinsicMetadata
    
    init(from decoder: ScaleDecoder) throws {
        modules = try decoder.decode([RuntimeModuleMetadataV12].self)
        extrinsic = try decoder.decode(RuntimeExtrinsicMetadataV4.self)
    }
    
    // Encodable
    enum CodingKeys: String, CodingKey {
        case version
        case modules
        case extrinsic
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(modules as! [RuntimeModuleMetadataV12], forKey: .modules)
        try container.encode(extrinsic as! RuntimeExtrinsicMetadataV4, forKey: .extrinsic)
    }
}

struct RuntimeModuleMetadataV12: ScaleDecodable, RuntimeModuleMetadata, Encodable {
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
    
    // Encodable
    enum CodingKeys: String, CodingKey {
        case name
        case storage
        case calls
        case events
        case constants
        case errors
        case index
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(storage as! Optional<RuntimeStorageMetadataV12>, forKey: .storage)
        try container.encode(calls as! Optional<[RuntimeCallMetadataV12]>, forKey: .calls)
        try container.encode(events as! Optional<[RuntimeEventMetadataV12]>, forKey: .events)
        try container.encode(constants as! [RuntimeConstantMetadataV12], forKey: .constants)
        try container.encode(errors as! [RuntimeErrorMetadataV12], forKey: .errors)
        try container.encode(index, forKey: .index)
    }
}

struct RuntimeStorageItemMetadataV12: ScaleDecodable, RuntimeStorageItemMetadata, Encodable {
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

struct RuntimeStorageMetadataV12: ScaleDecodable, RuntimeStorageMetadata, Encodable {
    public let prefix: String
    public let items: [RuntimeStorageItemMetadata]
    
    public init(from decoder: ScaleDecoder) throws {
        prefix = try decoder.decode()
        items = try decoder.decode([RuntimeStorageItemMetadataV12].self)
    }
    
    // Encodable
    enum CodingKeys: String, CodingKey {
        case prefix
        case items
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(prefix, forKey: .prefix)
        try container.encode(items as! [RuntimeStorageItemMetadataV12], forKey: .items)
    }
}

struct RuntimeCallArgumentsMetadataV12: ScaleDecodable, RuntimeCallArgumentsMetadata, Encodable {
    public let name: String
    public let type: String
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        type = try decoder.decode()
    }
}

struct RuntimeCallMetadataV12: ScaleDecodable, RuntimeCallMetadata, Encodable {
    public let name: String
    public let arguments: [RuntimeCallArgumentsMetadata]
    public let documentation: [String]
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        arguments = try decoder.decode([RuntimeCallArgumentsMetadataV12].self)
        documentation = try decoder.decode()
    }
    
    // Encodable
    enum CodingKeys: String, CodingKey {
        case name
        case arguments
        case documentation
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(arguments as! [RuntimeCallArgumentsMetadataV12], forKey: .arguments)
        try container.encode(documentation, forKey: .documentation)
    }
}

struct RuntimeEventMetadataV12: ScaleDecodable, RuntimeEventMetadata, Encodable {
    public let name: String
    public let arguments: [String]
    public let documentation: [String]
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        arguments = try decoder.decode()
        documentation = try decoder.decode()
    }
}

struct RuntimeConstantMetadataV12: ScaleDecodable, RuntimeConstantMetadata, Encodable {
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

struct RuntimeErrorMetadataV12: ScaleDecodable, RuntimeErrorMetadata, Encodable {
    public let name: String
    public let documentation: [String]
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        documentation = try decoder.decode()
    }
}
