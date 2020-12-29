//
//  MetadataModule.swift
//  
//
//  Created by Yehor Popovych on 12/29/20.
//

import Foundation
import SubstratePrimitives

public class MetadataModule {
    public let name: String
    public let index: UInt8
    
    public let errorsByIndex: Dictionary<UInt8, MetadataError>
    public let errorsByName: Dictionary<String, MetadataError>
    public let callsByName: Dictionary<String, MetadataCall>
    public let callsByIndex: Dictionary<UInt8, MetadataCall>
    public let eventsByIndex: Dictionary<UInt8, MetadataEvent>
    public let eventsByName: Dictionary<String, MetadataEvent>
    
    public let constants: Dictionary<String, MetadataConstant>
    public let storage: Dictionary<String, MetadataStorageItem>
    
    public init(runtime: RuntimeModuleMetadata) throws {
        name = runtime.name
        index = runtime.index
        
        let eTuples = runtime.errors.enumerated().map { ($0, $1.name, MetadataError(runtime: $1)) }
        errorsByName = Dictionary(uniqueKeysWithValues: eTuples.map { ($1, $2) })
        errorsByIndex = Dictionary(uniqueKeysWithValues: eTuples.map { (UInt8($0), $2) })
        
        let cTuples = try (runtime.calls ?? []).enumerated().map { ($0, $1.name, try MetadataCall(runtime: $1)) }
        callsByName = Dictionary(uniqueKeysWithValues: cTuples.map { ($1, $2) })
        callsByIndex = Dictionary(uniqueKeysWithValues: cTuples.map { (UInt8($0), $2) })
        
        let evTuples = try (runtime.events ?? []).enumerated().map { ($0, $1.name, try MetadataEvent(runtime: $1)) }
        eventsByName = Dictionary(uniqueKeysWithValues: evTuples.map { ($1, $2) })
        eventsByIndex = Dictionary(uniqueKeysWithValues: evTuples.map { (UInt8($0), $2) })
        
        let ctTuples = try runtime.constants.map { ($0.name, try MetadataConstant(runtime: $0)) }
        constants = Dictionary(uniqueKeysWithValues: ctTuples)
        
        if let storage = runtime.storage {
            let sTuples = try storage.items.map {
                ($0.name, try MetadataStorageItem(prefix: storage.prefix, runtime: $0))
            }
            self.storage = Dictionary(uniqueKeysWithValues: sTuples)
        } else {
            storage = [:]
        }
    }
}
