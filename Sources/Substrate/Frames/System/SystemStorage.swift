//
//  SystemStorage.swift
//  
//
//  Created by Yehor Popovych on 1/12/21.
//

import Foundation
import ScaleCodec

public struct SystemAccountStorageKey<S: System> {
    /// Account to retrieve the `AccountInfo<S>` for.
    public let accountId: S.TAccountId
}

extension SystemAccountStorageKey: MapStorageKey {
    public typealias Module = SystemModule<S>
    public typealias Value = AccountInfo<S>
    
    public static var FIELD: String { "Account" }
    
    public func encodeKey(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try accountId.encode(in: encoder, registry: registry)
    }
    
    public var path: [ScaleDynamicEncodable] { return [accountId] }
}
