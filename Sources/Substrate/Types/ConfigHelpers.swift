//
//  ConfigHelpers.swift
//  
//
//  Created by Yehor Popovych on 08/06/2023.
//

import Foundation
import ScaleCodec

public struct ExtrinsicFailureEvent<Err: SomeDispatchError>: SomeExtrinsicFailureEvent {
    public typealias Err = Err
    public static var pallet: String { "System" }
    public static var name: String { "ExtrinsicFailure" }
    
    public let error: Value<RuntimeTypeId>
    
    public init(params: [Value<RuntimeTypeId>]) throws {
        guard params.count == 1, let err = params.first else {
            throw ValueInitializableError<RuntimeTypeId>.wrongValuesCount(in: .sequence(params),
                                                                          expected: 1,
                                                                          for: Self.name)
        }
        self.error = err
    }
    
    public func asError() throws -> Err {
        try Err(value: error)
    }
}

public struct SystemEventsStorageKey<BE: SomeBlockEvents>: StaticStorageKey {
    public typealias TValue = BE
    
    public static var name: String { "Events" }
    public static var pallet: String { "System" }
    
    public init() {}
    
    public init(decodingPath decoder: ScaleDecoder, runtime: Runtime) throws {}
    public func encodePath(in encoder: ScaleEncoder, runtime: Runtime) throws {}
}


public struct MetadataRuntimeApi {
    public struct Metadata: StaticCodableRuntimeCall {
        public typealias TReturn = Data
        static public let method = "metadata"
        static public var api: String { MetadataRuntimeApi.name }
        
        public func encodeParams(in encoder: ScaleCodec.ScaleEncoder) throws {}
    }
    
    public struct MetadataAtVersion: StaticCodableRuntimeCall {
        public typealias TReturn = Optional<Data>
        let version: UInt32
        
        public init(version: UInt32) {
            self.version = version
        }
        
        public func encodeParams(in encoder: ScaleCodec.ScaleEncoder) throws {
            try encoder.encode(version)
        }
        
        static public let method = "metadata_at_version"
        static public var api: String { MetadataRuntimeApi.name }
    }
    
    public struct MetadataVersions: StaticCodableRuntimeCall {
        public typealias TReturn = [UInt32]
        static public let method = "metadata_versions"
        static public var api: String { MetadataRuntimeApi.name }
        
        public func encodeParams(in encoder: ScaleCodec.ScaleEncoder) throws {}
    }
    
    public static let name = "Metadata"
}
