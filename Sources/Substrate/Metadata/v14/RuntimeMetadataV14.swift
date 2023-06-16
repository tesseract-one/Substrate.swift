//
//  RuntimeMetadataV14.swift
//  
//
//  Created by Yehor Popovych on 12/29/22.
//

import Foundation
import ScaleCodec

public struct RuntimePalletMetadataV14: ScaleCodable {
    public let name: String
    public let storage: Optional<RuntimePalletStorageMedatadaV14>
    public let call: Optional<RuntimeTypeId>
    public let event: Optional<RuntimeTypeId>
    public let constants: [RuntimePalletConstantMetadataV14]
    public let error: Optional<RuntimeTypeId>
    public let index: UInt8
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        storage = try decoder.decode()
        call = try decoder.decode()
        event = try decoder.decode()
        constants = try decoder.decode()
        error = try decoder.decode()
        index = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(name)
            .encode(storage)
            .encode(call)
            .encode(event)
            .encode(constants)
            .encode(error)
            .encode(index)
    }
}

public struct RuntimePalletStorageMedatadaV14: ScaleCodable {
    public let prefix: String
    public let entries: [RuntimePalletStorageEntryMedatadaV14]
    
    public init(from decoder: ScaleDecoder) throws {
        prefix = try decoder.decode()
        entries = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(prefix).encode(entries)
    }
}

public enum RuntimePalletStorageEntryTypeV14: ScaleCodable {
    case plain(_ value: RuntimeTypeId)
    case map(hashers: [StorageHasher], key: RuntimeTypeId, value: RuntimeTypeId)
    
    public init(from decoder: ScaleDecoder) throws {
        let caseId = try decoder.decode(.enumCaseId)
        switch caseId {
        case 0: self = try .plain(decoder.decode())
        case 1:
            self = try .map(hashers: decoder.decode(),
                            key: decoder.decode(),
                            value: decoder.decode())
        default: throw decoder.enumCaseError(for: caseId)
        }
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        switch self {
        case .plain(let ty): try encoder.encode(0, .enumCaseId).encode(ty)
        case .map(hashers: let hashers, key: let key, value: let value):
            try encoder.encode(1, .enumCaseId).encode(hashers).encode(key).encode(value)
        }
    }
}

public struct RuntimePalletStorageEntryMedatadaV14: ScaleCodable {
    public let name: String
    public let modifier: StorageEntryModifier
    public let type: RuntimePalletStorageEntryTypeV14
    public let defaultValue: Data
    public let documentation: [String]
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        modifier = try decoder.decode()
        type = try decoder.decode()
        defaultValue = try decoder.decode()
        documentation = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(name).encode(modifier).encode(type)
            .encode(defaultValue).encode(documentation)
    }
}

public struct RuntimePalletConstantMetadataV14: ScaleCodable {
    public let name: String
    public let type: RuntimeTypeId
    public let value: Data
    public let documentation: [String]
    
    public init(from decoder: ScaleDecoder) throws {
        name = try decoder.decode()
        type = try decoder.decode()
        value = try decoder.decode()
        documentation = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(name).encode(type)
            .encode(value).encode(documentation)
    }
}

public struct RuntimeExtrinsicMetadataV14: ScaleCodable {
    public let type: RuntimeTypeId
    public let version: UInt8
    public let signedExtensions: [RuntimeExtrinsicSignedExtensionV14]
    
    public init(from decoder: ScaleDecoder) throws {
        type = try decoder.decode()
        version = try decoder.decode()
        signedExtensions = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(type).encode(version).encode(signedExtensions)
    }
}

public struct RuntimeExtrinsicSignedExtensionV14: ScaleCodable {
    public let identifier: String
    public let type: RuntimeTypeId
    public let additionalSigned: RuntimeTypeId
    
    public init(from decoder: ScaleDecoder) throws {
        identifier = try decoder.decode()
        type = try decoder.decode()
        additionalSigned = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(identifier)
            .encode(type)
            .encode(additionalSigned)
    }
}

public class RuntimeMetadataV14: ScaleCodable, RuntimeMetadata {
    public var version: UInt8 { 14 }
    public let types: [RuntimeTypeInfo]
    public let pallets: [RuntimePalletMetadataV14]
    public let extrinsic: RuntimeExtrinsicMetadataV14
    public let runtimeType: RuntimeTypeId
    
    required public init(from decoder: ScaleDecoder) throws {
        types = try decoder.decode()
        pallets = try decoder.decode()
        extrinsic = try decoder.decode()
        runtimeType = try decoder.decode()
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        try encoder.encode(types).encode(pallets)
            .encode(extrinsic).encode(runtimeType)
    }
    
    public func asMetadata() throws -> Metadata {
        try MetadataV14(runtime: self)
    }
    
    public class var versions: Set<UInt32> { [14] }
}
