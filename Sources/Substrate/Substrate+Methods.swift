//
//  Substrate+Methods.swift
//  
//
//  Created by Yehor Popovych on 1/13/21.
//

import Foundation

extension SubstrateProtocol {
    public func defaultValue(for key: AnyStorageKey) throws -> DValue { try registry.defaultValue(for: key) }
    public func value(of constant: AnyConstant) throws -> DValue { try registry.value(of: constant) }
    
    public func getValue(for key: AnyStorageKey, _ cb: @escaping SApiCallback<DValue>) {
        state.getStorage(dynamic: key, cb)
    }
}
