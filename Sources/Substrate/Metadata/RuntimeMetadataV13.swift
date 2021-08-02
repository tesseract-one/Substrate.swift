//
//  RuntimeMetadataV13.swift
//  
//
//  Created by Yehor Popovych on 12/29/20.
//

import Foundation
import ScaleCodec
#if !COCOAPODS
import SubstratePrimitives
#endif

struct RuntimeMetadataV13: ScaleDecodable, RuntimeMetadata, Encodable {
    var version: UInt8 { 13  }
    let modules: [RuntimeModuleMetadata]
    let extrinsic: RuntimeExtrinsicMetadata
    
    init(from decoder: ScaleDecoder) throws {
        modules = try decoder.decode([RuntimeModuleMetadataV13].self)
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
        try container.encode(modules as! [RuntimeModuleMetadataV13], forKey: .modules)
        try container.encode(extrinsic as! RuntimeExtrinsicMetadataV4, forKey: .extrinsic)
    }
}

struct RuntimeModuleMetadataV13: ScaleDecodable, RuntimeModuleMetadata, Encodable {
    public let name: String
    public let storage: Optional<RuntimeStorageMetadata>
    public let calls: Optional<[RuntimeCallMetadata]>
    public let events: Optional<[RuntimeEventMetadata]>
    public let constants: [RuntimeConstantMetadata]
    public let errors: [RuntimeErrorMetadata]
    public let index: UInt8
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        storage = try decoder.decode(Optional<RuntimeStorageMetadataV13>.self)
        calls = try decoder.decode(Optional<[RuntimeCallMetadataV13]>.self)
        events = try decoder.decode(Optional<[RuntimeEventMetadataV13]>.self)
        constants = try decoder.decode([RuntimeConstantMetadataV13].self)
        errors = try decoder.decode([RuntimeErrorMetadataV13].self)
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
        try container.encode(storage as! Optional<RuntimeStorageMetadataV13>, forKey: .storage)
        try container.encode(calls as! Optional<[RuntimeCallMetadataV13]>, forKey: .calls)
        try container.encode(events as! Optional<[RuntimeEventMetadataV13]>, forKey: .events)
        try container.encode(constants as! [RuntimeConstantMetadataV13], forKey: .constants)
        try container.encode(errors as! [RuntimeErrorMetadataV13], forKey: .errors)
        try container.encode(index, forKey: .index)
    }
}

struct RuntimeStorageItemMetadataV13: ScaleDecodable, RuntimeStorageItemMetadata, Encodable {
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

struct RuntimeStorageMetadataV13: ScaleDecodable, RuntimeStorageMetadata, Encodable {
    public let prefix: String
    public let items: [RuntimeStorageItemMetadata]
    
    public init(from decoder: ScaleDecoder) throws {
        prefix = try decoder.decode()
        items = try decoder.decode([RuntimeStorageItemMetadataV13].self)
    }
    
    // Encodable
    enum CodingKeys: String, CodingKey {
        case prefix
        case items
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(prefix, forKey: .prefix)
        try container.encode(items as! [RuntimeStorageItemMetadataV13], forKey: .items)
    }
}

struct RuntimeCallArgumentsMetadataV13: ScaleDecodable, RuntimeCallArgumentsMetadata, Encodable {
    public let name: String
    public let type: String
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        type = try decoder.decode()
    }
}

struct RuntimeCallMetadataV13: ScaleDecodable, RuntimeCallMetadata, Encodable {
    public let name: String
    public let arguments: [RuntimeCallArgumentsMetadata]
    public let documentation: [String]
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        arguments = try decoder.decode([RuntimeCallArgumentsMetadataV13].self)
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
        try container.encode(arguments as! [RuntimeCallArgumentsMetadataV13], forKey: .arguments)
        try container.encode(documentation, forKey: .documentation)
    }
}

struct RuntimeEventMetadataV13: ScaleDecodable, RuntimeEventMetadata, Encodable {
    public let name: String
    public let arguments: [String]
    public let documentation: [String]
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        arguments = try decoder.decode()
        documentation = try decoder.decode()
    }
}

struct RuntimeConstantMetadataV13: ScaleDecodable, RuntimeConstantMetadata, Encodable {
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

struct RuntimeErrorMetadataV13: ScaleDecodable, RuntimeErrorMetadata, Encodable {
    public let name: String
    public let documentation: [String]
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        documentation = try decoder.decode()
    }
}
