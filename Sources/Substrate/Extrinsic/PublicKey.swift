//
//  PublicKey.swift
//  
//
//  Created by Yehor Popovych on 20.04.2023.
//

import Foundation
import ScaleCodec

public protocol PublicKey: RuntimeCodable, Hashable, Equatable {
    var raw: Data { get }
    var algorithm: CryptoTypeId { get }
    
    init(_ raw: Data) throws
    
    func account<A: AccountId>(runtime: any Runtime) throws -> A
    func address<A: Address>(runtime: any Runtime) throws -> A
}

public extension PublicKey {
    @inlinable
    static func from(ss58: String) throws -> (Self, SS58.AddressFormat){
        let (raw, format) = try SS58.decode(string: ss58)
        return try (Self(raw), format)
    }
    
    @inlinable
    func ss58(format: SS58.AddressFormat) -> String {
        SS58.encode(data: raw, format: format)
    }
    
    @inlinable
    func account<A: AccountId>(runtime: any Runtime) throws -> A {
        try runtime.create(account: A.self, pub: self)
    }
    
    @inlinable
    func address<A: Address>(runtime: any Runtime) throws -> A {
        let account: A.TAccountId = try self.account(runtime: runtime)
        return try account.address()
    }
    
    @inlinable
    func account<A: RootApi>(in api: A) throws -> A.RC.TAccountId {
        try api.runtime.account(pub: self)
    }
    
    @inlinable
    func address<A: RootApi>(in api: A) throws -> A.RC.TAddress {
        try api.runtime.address(pub: self)
    }
}
