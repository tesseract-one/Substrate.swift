//
//  AccountList.swift
//  
//
//  Created by Yehor Popovych on 06.05.2021.
//

import Foundation

public struct AccountList<R: Runtime> {
    public let accounts: Array<PublicKey>
    
    public init(accounts: [PublicKey]) {
        self.accounts = accounts
    }
    
    public func list<P: PublicKey>(for type: P.Type) -> Array<P> {
        accounts
            .filter { $0.typeId == type.typeId }
            .map { try! P(bytes: $0.bytes, format: $0.format) }
    }
    
    public var chain: Array<R.TAccountId> {
        list(for: R.TAccountId.self)
    }
}

extension AccountList where R: Babe {
    public var babe: Array<R.TKeys.TBabe.TPublic> {
        list(for: R.TKeys.TBabe.TPublic.self)
    }
}

extension AccountList where R: Grandpa {
    public var grandpa: Array<R.TKeys.TGrandpa.TPublic> {
        list(for: R.TKeys.TGrandpa.TPublic.self)
    }
}

extension AccountList where R: ImOnline {
    public var imOnline: Array<R.TKeys.TImOnline.TPublic> {
        list(for: R.TKeys.TImOnline.TPublic.self)
    }
}

extension AccountList where R: AuthorityDiscovery {
    public var authorityDiscovery: Array<R.TKeys.TAuthorityDiscovery.TPublic> {
        list(for: R.TKeys.TAuthorityDiscovery.TPublic.self)
    }
}

extension AccountList where R: Parachains {
    public var parachains: Array<R.TKeys.TParachains.TPublic> {
        list(for: R.TKeys.TParachains.TPublic.self)
    }
}
