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
    public static var definition: FrameTypeDefinition {
        .event(Self.self, fields: [.v(DispatchError.definition), .v(DispatchInfo.definition)])
    }
    
    public static let pallet: String = "System"
    public static let name: String = "ExtrinsicFailed"
}

