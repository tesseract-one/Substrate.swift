//
//  Registry.swift
//  
//
//  Created by Yehor Popovych on 30.12.2022.
//

import Foundation
import ScaleCodec

public protocol Registry: AnyObject {
    var addressFormat: SS58.AddressFormat { get }
    var metadata: Metadata { get }
    var types: [RuntimeTypeId: RuntimeType] { get }
    
    init(metadata: Metadata, addressFormat: SS58.AddressFormat) throws
}

public protocol RegistryOwner {
    var registry: Registry { get set }
}

public class DynamicTypeRegistry: Registry {
    public let addressFormat: SS58.AddressFormat
    public let metadata: Metadata
    public let types: [RuntimeTypeId: RuntimeType]
    
    required public init(metadata: Metadata, addressFormat: SS58.AddressFormat) throws {
        self.metadata = metadata
        self.addressFormat = addressFormat
        self.types = Dictionary<RuntimeTypeId, RuntimeType>(
            uniqueKeysWithValues: metadata.types.map { ($0.id, $0.type) }
        )
    }
}
