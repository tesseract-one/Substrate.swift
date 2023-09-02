//
//  AnyExtrinsicFailureEvent.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import ScaleCodec

public struct AnyExtrinsicFailureEvent: SomeExtrinsicFailureEvent {
    public struct ExtrinsicFailed: Error {
        public let body: Value<NetworkType.Id>
    }
    public typealias Err = ExtrinsicFailed
    public let error: ExtrinsicFailed
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, as type: NetworkType.Id, runtime: Runtime) throws {
        let value = try Value<NetworkType.Id>(from: &decoder, as: type, runtime: runtime)
        self.error = ExtrinsicFailed(body: value)
    }
    
    public static func validate(runtime: Runtime) -> Result<Void, ValidationError> {
        .success(())
    }
    
    public static let pallet: String = "System"
    public static let name: String = "ExtrinsicFailed"
}
