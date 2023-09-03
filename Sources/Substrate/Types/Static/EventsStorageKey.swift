//
//  EventsStorageKey.swift
//  
//
//  Created by Yehor Popovych on 18/08/2023.
//

import Foundation
import ScaleCodec

public struct EventsStorageKey<BE: SomeBlockEvents>: PlainStorageKey, ComplexStaticFrameType {
    public typealias TParams = Void
    public typealias TBaseParams = Void
    public typealias TypeInfo = StorageKeyTypeInfo
    public typealias ChildTypes = StorageKeyChildTypes
    public typealias TValue = BE
    
    public static var pallet: String { "System" }
    public static var name: String { "Events" }
    
    public init() {}
    
    public static func decode<D:ScaleCodec.Decoder>(
        valueFrom decoder: inout D, runtime: Runtime
    ) throws -> BE {
        try runtime.decode(from: &decoder) { runtime in
            guard let key = runtime.resolve(storage: Self.name, pallet: Self.pallet) else {
                throw StorageKeyCodingError.storageNotFound(name: Self.name, pallet: Self.pallet)
            }
            return key.value.id
        }
    }
}
