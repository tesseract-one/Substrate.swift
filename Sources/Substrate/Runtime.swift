//
//  Runtime.swift
//  
//
//  Created by Yehor Popovych on 29.12.2022.
//

import Foundation
import ScaleCodec

public protocol Runtime {
    associatedtype THash: Hash
    associatedtype TBlockNumber: AnyBlockNumber
    associatedtype TRuntimeVersion: RuntimeVersion
    associatedtype TSystemProperties: SystemProperties
}

public struct DynamicRuntime: Runtime {
    public typealias THash = DynamicHash
    public typealias TBlockNumber = UInt256
    public typealias TRuntimeVersion = DynamicRuntimeVersion
    public typealias TSystemProperties = DynamicSystemProperties
    
    public init() {}
}

