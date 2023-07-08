//
//  RuntimeTypes.swift
//  
//
//  Created by Yehor Popovych on 07/07/2023.
//

import Foundation
import ScaleCodec

public extension RuntimeType {
    typealias LazyId = (Runtime) throws -> Id
    
    struct IdNeverCalledError: Error, CustomStringConvertible {
        public var description: String { "Asked for IdNever" }
        public init() {}
    }
    
    static func IdNever(_ r: Runtime) throws -> RuntimeType.Id { throw IdNeverCalledError() }
}

public protocol RuntimeTypes {
    var block: RuntimeType.Info { get throws }
    var blockHeader: RuntimeType.Info { get throws }
    var account: RuntimeType.Info { get throws }
    var address: RuntimeType.Info { get throws }
    var signature: RuntimeType.Info { get throws }
    var call: RuntimeType.Info { get throws }
    var event: RuntimeType.Info { get throws }
    var extrinsicExtra: RuntimeType.Info { get throws }
    var dispatchInfo: RuntimeType.Info { get throws }
    var dispatchError: RuntimeType.Info { get throws }
    var feeDetails: RuntimeType.Info { get throws }
    var transactionValidityError: RuntimeType.Info { get throws }
}

public extension Runtime {
    @inlinable
    func decode<E: Event>(event: E.Type, from data: Data) throws -> E {
        try decode(from: data) { try $0.types.event.id }
    }
    
    @inlinable
    func decode<E: Event, D: ScaleCodec.Decoder>(
        event: E.Type, from decoder: inout D
    ) throws -> E {
        try decode(from: &decoder) { try $0.types.event.id }
    }
}

public struct LazyRuntimeTypes<RC: Config>: RuntimeTypes {
    private struct State {
        var blockHeader: Result<RuntimeType.Info, Error>?
        var extrinsic: Result<(call: RuntimeType.Info, addr: RuntimeType.Info,
                               signature: RuntimeType.Info, extra: RuntimeType.Info), Error>?
        var event: Result<RuntimeType.Info, Error>?
        var dispatchInfo: Result<RuntimeType.Info, Error>?
        var dispatchError: Result<RuntimeType.Info, Error>?
        var feeDetails: Result<RuntimeType.Info, Error>?
        var transactionValidityError: Result<RuntimeType.Info, Error>?
    }
    
    private var _state: Synced<State>
    private var _config: RC
    private var _metadata: any Metadata
    
    public init(config: RC, metadata: any Metadata) {
        self._state = Synced(value: State())
        self._config = config
        self._metadata = metadata
    }
    
    public var blockHeader: RuntimeType.Info { get throws {
        try _state.sync { state in
            if let res = state.blockHeader { return try res.get() }
            state.blockHeader = Result { try self._config.blockHeaderType(metadata: self._metadata) }
            return try state.blockHeader!.get()
        }
    }}
    
    public var call: RuntimeType.Info { get throws { try _extrinsic.call }}
    public var address: RuntimeType.Info { get throws { try _extrinsic.addr } }
    public var signature: RuntimeType.Info { get throws { try _extrinsic.signature }}
    public var extrinsicExtra: RuntimeType.Info { get throws { try _extrinsic.extra }}
    
    public var dispatchInfo: RuntimeType.Info { get throws {
        try _state.sync { state in
            if let res = state.dispatchInfo { return try res.get() }
            state.dispatchInfo = Result { try self._config.dispatchInfoType(metadata: self._metadata) }
            return try state.dispatchInfo!.get()
        }
    }}
    
    public var dispatchError: RuntimeType.Info { get throws {
        try _state.sync { state in
            if let res = state.dispatchError { return try res.get() }
            state.dispatchError = Result { try self._config.dispatchErrorType(metadata: self._metadata) }
            return try state.dispatchError!.get()
        }
    }}
    
    public var feeDetails: RuntimeType.Info { get throws {
        try _state.sync { state in
            if let res = state.feeDetails { return try res.get() }
            state.feeDetails = Result { try self._config.feeDetailsType(metadata: self._metadata) }
            return try state.feeDetails!.get()
        }
    }}
    
    public var transactionValidityError: RuntimeType.Info { get throws {
        try _state.sync { state in
            if let res = state.transactionValidityError { return try res.get() }
            state.transactionValidityError = Result {
                try self._config.transactionValidityErrorType(metadata: self._metadata)
            }
            return try state.transactionValidityError!.get()
        }
    }}
    
    public var event: RuntimeType.Info { get throws {
        try _state.sync { state in
            if let res = state.event { return try res.get() }
            if let event = _metadata.enums?.eventType {
                state.event = .success(event)
            } else {
                state.event = Result { try _config.eventType(metadata: _metadata) }
            }
            return try state.event!.get()
        }
    }}
    
    
    private var _extrinsic: (call: RuntimeType.Info, addr: RuntimeType.Info,
                             signature: RuntimeType.Info, extra: RuntimeType.Info)
    { get throws {
        try _state.sync { state in
            if let res = state.extrinsic { return try res.get() }
            if let call = _metadata.extrinsic.callType,
               let addr = _metadata.extrinsic.addressType,
               let signature = _metadata.extrinsic.signatureType,
               let extra = _metadata.extrinsic.extraType
            {
                state.extrinsic = .success((call, addr, signature, extra))
            } else {
                state.extrinsic = Result { try self._config.extrinsicTypes(metadata: self._metadata) }
            }
            return try state.extrinsic!.get()
        }
    }}
}
