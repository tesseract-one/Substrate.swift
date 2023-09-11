//
//  AnyExtrinsicFailureEvent.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec

public struct AnyExtrinsicFailureEvent: SomeExtrinsicFailureEvent,
                                        RuntimeDynamicDecodable,
                                        ComplexFrameType {
    public typealias TypeInfo = EventTypeInfo
    
    public struct ExtrinsicFailed: Error {
        public let body: Value<TypeDefinition>
    }
    public typealias Err = ExtrinsicFailed
    public let error: ExtrinsicFailed
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, as type: TypeDefinition, runtime: Runtime) throws {
        let event = try AnyEvent(from: &decoder, as: type, runtime: runtime)
        guard event.name == Self.name, event.pallet == Self.pallet else {
            throw FrameTypeError.foundWrongType(for: Self.self, name: event.name,
                                                frame: event.pallet, .get())
        }
        self.error = ExtrinsicFailed(body: event.params)
    }
    
    public static func validate(info: TypeInfo,
                                in runtime: any Runtime) -> Result<Void, FrameTypeError>
    {
        .success(())
    }
    
    public static let pallet: String = "System"
    public static let name: String = "ExtrinsicFailed"
}
