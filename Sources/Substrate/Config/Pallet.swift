//
//  PalletType.swift
//  
//
//  Created by Yehor Popovych on 31/08/2023.
//

import Foundation

public protocol PalletType {
    static var pallet: String { get }
    static var name: String { get }
}

public extension PalletType {
    var name: String { Self.name }
    var pallet: String { Self.pallet }
}

public protocol Pallet {
    static var name: String { get }
    
    var calls: [(Call & PalletType & RuntimeValidatable).Type] { get }
    var events: [(Event & PalletType & RuntimeValidatable).Type] { get }
    var storageKeys: [any (StorageKey & PalletType & RuntimeValidatable).Type] { get }
    var constants: [any (StaticConstant & PalletType & RuntimeValidatable).Type] { get }
    
    func validate(runtime: any Runtime) -> Result<Void, ValidationError>
}

public extension Pallet {
    func validate(runtime: any Runtime) -> Result<Void, ValidationError> {
        calls.voidErrorMap { $0.validate(runtime: runtime) }
            .flatMap { events.voidErrorMap { $0.validate(runtime: runtime) } }
            .flatMap { storageKeys.voidErrorMap { $0.validate(runtime: runtime) } }
            .flatMap { constants.voidErrorMap { $0.validate(runtime: runtime) } }
    }
}

public protocol PalletCall: Call, PalletType, RuntimeValidatable {
    associatedtype TPallet: Pallet
}

public extension PalletCall {
    static var pallet: String { TPallet.name }
}

public protocol PalletEvent: Event, PalletType, RuntimeValidatable {
    associatedtype TPallet: Pallet
}

public extension PalletEvent {
    static var pallet: String { TPallet.name }
}

public protocol PalletStorageKey: StorageKey, PalletType, RuntimeValidatable {
    associatedtype TPallet: Pallet
}

public extension PalletStorageKey {
    static var pallet: String { TPallet.name }
}

public protocol PalletConstant: StaticConstant, PalletType, RuntimeValidatable {
    associatedtype TPallet: Pallet
}

public extension PalletConstant {
    static var pallet: String { TPallet.name }
}

public extension Configs {
    struct BaseSystemPallet<C: Config>: Pallet {
        @inlinable
        public static var name: String { "System" }
        @inlinable
        public var events: [(Event & PalletType & RuntimeValidatable).Type] {
            [ST<C>.ExtrinsicFailureEvent.self]
        }
        @inlinable
        public var storageKeys: [any (PalletType & RuntimeValidatable & StorageKey).Type] {
            [EventsStorageKey<ST<C>.BlockEvents>.self]
        }
        @inlinable
        public var constants: [any (RuntimeValidatable & StaticConstant).Type] { [] }
        
        public let calls: [(Call & PalletType & RuntimeValidatable).Type]
        
        public init(runtime: any Runtime, config: C) throws {
            if let batch = config as? any BatchSupportedConfig,
               batch.isBatchSupported(metadata: runtime.metadata)
            {
                self.calls = try batch.batchCalls(runtime: runtime)
            } else {
                self.calls = []
            }
        }
    }
}
