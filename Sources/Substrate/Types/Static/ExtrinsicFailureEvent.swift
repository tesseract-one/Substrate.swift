//
//  ExtrinsicFailureEvent.swift
//  
//
//  Created by Yehor Popovych on 24/08/2023.
//

import Foundation
import ScaleCodec

public struct ExtrinsicFailureEvent: SomeExtrinsicFailureEvent, StaticEvent, IdentifiableFrameType {
    public struct ExtrinsicFailed: Error {
        public let error: DispatchError
        public let info: DispatchInfo
    }
    public typealias Err = ExtrinsicFailed
    
    public let error: ExtrinsicFailed
    
    public init<D: ScaleCodec.Decoder>(paramsFrom decoder: inout D, runtime: Runtime) throws {
        self.error = ExtrinsicFailed(error: try runtime.decode(from: &decoder),
                                     info: try decoder.decode())
    }
    
    @inlinable
    public static func definition(in registry: TypeRegistry<TypeDefinition.TypeId>) -> FrameTypeDefinition {
        .event(fields: [
            .v(registry.def(DispatchError.self)), .v(registry.def(DispatchInfo.self))
        ])
    }
    
    public static let pallet: String = "System"
    public static let name: String = "ExtrinsicFailed"
}

