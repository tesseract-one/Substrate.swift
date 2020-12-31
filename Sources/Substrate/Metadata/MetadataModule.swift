//
//  MetadataModule.swift
//  
//
//  Created by Yehor Popovych on 12/29/20.
//

import Foundation
import SubstratePrimitives

public class MetadataModuleInfo {
    public let name: String
    public let index: UInt8
    
    public let errorsByIndex: Dictionary<UInt8, MetadataDynamicError>
    public let errorsByName: Dictionary<String, MetadataDynamicError>
    public let callsByName: Dictionary<String, MetadataCallInfo>
    public let callsByIndex: Dictionary<UInt8, MetadataCallInfo>
    public let eventsByIndex: Dictionary<UInt8, MetadataEventInfo>
    public let eventsByName: Dictionary<String, MetadataEventInfo>
    
    public let constants: Dictionary<String, MetadataConstantInfo>
    public let storage: Dictionary<String, MetadataStorageItemInfo>
    
    public init(runtime: RuntimeModuleMetadata) throws {
        name = runtime.name
        index = runtime.index
        
        let eTuples = runtime.errors.enumerated().map { ($0, $1.name, MetadataDynamicError(runtime: $1)) }
        errorsByName = Dictionary(uniqueKeysWithValues: eTuples.map { ($1, $2) })
        errorsByIndex = Dictionary(uniqueKeysWithValues: eTuples.map { (UInt8($0), $2) })
        
        let cTuples = try (runtime.calls ?? []).enumerated().map { ($0, $1.name, try MetadataCallInfo(runtime: $1)) }
        callsByName = Dictionary(uniqueKeysWithValues: cTuples.map { ($1, $2) })
        callsByIndex = Dictionary(uniqueKeysWithValues: cTuples.map { (UInt8($0), $2) })
        
        let evTuples = try (runtime.events ?? []).enumerated().map { ($0, $1.name, try MetadataEventInfo(runtime: $1)) }
        eventsByName = Dictionary(uniqueKeysWithValues: evTuples.map { ($1, $2) })
        eventsByIndex = Dictionary(uniqueKeysWithValues: evTuples.map { (UInt8($0), $2) })
        
        let ctTuples = try runtime.constants.map { ($0.name, try MetadataConstantInfo(runtime: $0)) }
        constants = Dictionary(uniqueKeysWithValues: ctTuples)
        
        if let storage = runtime.storage {
            let sTuples = try storage.items.map {
                ($0.name, try MetadataStorageItemInfo(prefix: storage.prefix, runtime: $0))
            }
            self.storage = Dictionary(uniqueKeysWithValues: sTuples)
        } else {
            storage = [:]
        }
    }
}
