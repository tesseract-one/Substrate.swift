//
//  BatchCalls.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec

public protocol BatchCallCommon: SomeBatchCall, ComplexStaticFrameType
    where TypeInfo == CallTypeInfo, ChildTypes == CallChildTypes {}

public extension BatchCallCommon {
    func add(_ call: any Call) -> Self { Self(calls: calls + [call]) }
    
    @inlinable static var pallet: String { "Utility" }
    
    init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws {
        let modIndex = try decoder.decode(.enumCaseId)
        let callIndex = try decoder.decode(.enumCaseId)
        guard let info = runtime.resolve(callName: callIndex, pallet: modIndex) else {
            throw FrameTypeError.typeInfoNotFound(for: Self.self, index: callIndex,
                                                  frame: modIndex, .get())
        }
        guard Self.pallet == info.pallet && Self.name == info.name else {
            throw FrameTypeError.foundWrongType(for: Self.self, name: info.name,
                                                frame: info.pallet, .get())
        }
        let calls = try Array<AnyCall<TypeDefinition>>(from: &decoder) { decoder in
            try AnyCall(from: &decoder, runtime: runtime)
        }
        self.init(calls: calls)
    }
    
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
        guard let info = runtime.resolve(callIndex: name, pallet: pallet) else {
            throw FrameTypeError.typeInfoNotFound(for: Self.self, .get())
        }
        try encoder.encode(info.pallet, .enumCaseId)
        try encoder.encode(info.index, .enumCaseId)
        try calls.encode(in: &encoder) { call, enc in
            try runtime.encode(value: call, in: &enc)
        }
    }
    
    @inlinable
    static var childTypes: ChildTypes { [Array<AnyCall<TypeDefinition>>.self] }
}

public struct BatchCall: BatchCallCommon {
    public let calls: [any Call]
    public init(calls: [any Call]) {
        self.calls = calls
    }
    public static let name = "batch"
}

public struct BatchAllCall: BatchCallCommon {
    public let calls: [any Call]
    public init(calls: [any Call]) {
        self.calls = calls
    }
    public static let name = "batch_all"
}
