//
//  Metadata.swift
//  
//
//  Created by Yehor Popovych on 12/29/20.
//

import Foundation
import ScaleCodec
import SubstratePrimitives

public class Metadata {
    public let modulesByName: Dictionary<String, MetadataModule>
    public let modulesByIndex: Dictionary<UInt8, MetadataModule>
    public let signedExtensions: [Any]
    
    public init(runtime: RuntimeMetadata) throws {
        let modules = try runtime.modules.map { try ($0.name, $0.index, MetadataModule(runtime: $0)) }
        let modulesByName = modules.map { ($0, $2) }
        let modulesByIndex = modules.map { ($1, $2) }
        self.modulesByName = Dictionary(uniqueKeysWithValues: modulesByName)
        self.modulesByIndex = Dictionary(uniqueKeysWithValues: modulesByIndex)
        signedExtensions = runtime.extrinsic.signedExtensions
    }
}

extension Metadata: SubstratePrimitives.Metadata {
    // StorageKey
    public func prefix<K: AnyStorageKey>(for key: K, with registry: SubstratePrimitives.TypeRegistry) throws -> Data {
        fatalError("Not implemented")
    }
    public func key<K: AnyStorageKey>(for key: K, with registry: SubstratePrimitives.TypeRegistry) throws -> Data {
        fatalError("Not implemented")
    }

    // Call
    public func encode<T: AnyCall>(call: T, in encoder: ScaleEncoder, with registry: SubstratePrimitives.TypeRegistry) throws {
        fatalError("Not implemented")
    }
    public func decode(call index: Int, module: Int, from decoder: ScaleDecoder, with registry: SubstratePrimitives.TypeRegistry) throws -> AnyCall {
        fatalError("Not implemented")
    }
    public func find(call: Int, module: Int) -> (module: String, function: String)? {
        fatalError("Not implemented")
    }

    // Event
    public func decode(event index: Int, module: Int, from decoder: ScaleDecoder, with registry: SubstratePrimitives.TypeRegistry) throws -> AnyEvent {
        fatalError("Not implemented")
    }
    public func find(event: Int, module: Int) -> (module: String, event: String)? {
        fatalError("Not implemented")
    }

    // Generic Values
    public func encode(
        value: ScaleRegistryEncodable, type: SType,
        in encoder: ScaleEncoder, with registry: SubstratePrimitives.TypeRegistry
    ) throws {
        fatalError("Not implemented")
    }

    public func decode(
        type: SType, from decoder: ScaleDecoder, with registry: SubstratePrimitives.TypeRegistry
    ) throws -> ScaleRegistryDecodable {
        fatalError("Not implemented")
    }
}
