//
//  Frame.swift
//  
//
//  Created by Yehor Popovych on 31/08/2023.
//

import Foundation

public protocol Frame {
    static var name: String { get }
    
    var calls: [PalletCall.Type] { get }
    var events: [PalletEvent.Type] { get }
    var storageKeys: [any PalletStorageKey.Type] { get }
    var constants: [any StaticConstant.Type] { get }
    
    func validate(runtime: any Runtime) -> Result<Void, FrameTypeError>
}

public extension Frame {
    func validate(runtime: any Runtime) -> Result<Void, FrameTypeError> {
        calls.voidErrorMap { $0.validate(runtime: runtime) }
            .flatMap { events.voidErrorMap { $0.validate(runtime: runtime) } }
            .flatMap { storageKeys.voidErrorMap { $0.validate(runtime: runtime) } }
            .flatMap { constants.voidErrorMap { $0.validate(runtime: runtime) } }
    }
}

public protocol FrameCall: PalletCall {
    associatedtype TFrame: Frame
}

public extension FrameCall {
    static var pallet: String { TFrame.name }
}

public protocol FrameEvent: Event, FrameType {
    associatedtype TFrame: Frame
}

public extension FrameEvent {
    static var pallet: String { TFrame.name }
}

public protocol FrameStorageKey: StorageKey, FrameType {
    associatedtype TFrame: Frame
}

public extension FrameStorageKey {
    static var pallet: String { TFrame.name }
}

public protocol FrameConstant: StaticConstant {
    associatedtype TFrame: Frame
}

public extension FrameConstant {
    static var pallet: String { TFrame.name }
}

public extension Configs {
    struct BaseSystemFrame<C: Config>: Frame {
        @inlinable
        public static var name: String { "System" }
        @inlinable
        public var events: [PalletEvent.Type] {
            [ST<C>.ExtrinsicFailureEvent.self]
        }
        @inlinable
        public var storageKeys: [any PalletStorageKey.Type] {
            [EventsStorageKey<ST<C>.BlockEvents>.self]
        }
        @inlinable
        public var constants: [any StaticConstant.Type] { [] }
        
        public let calls: [PalletCall.Type]
        
        public init(runtime: any Runtime, config: C) throws {
            if let batch = config as? any BatchSupportedConfig,
               batch.isBatchSupported(types: runtime.types, metadata: runtime.metadata)
            {
                self.calls = try batch.batchCalls(runtime: runtime)
            } else {
                self.calls = []
            }
        }
    }
}
