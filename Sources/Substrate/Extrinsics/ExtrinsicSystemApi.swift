//
//  ExtrinsicSystemApi.swift
//  
//
//  Created by Yehor Popovych on 2/7/21.
//

import Foundation

public struct SubstrateExtrinsicSystemApi<S: SubstrateProtocol>: SubstrateExtrinsicApi {
    public weak var substrate: S!

    public init(substrate: S) {
        self.substrate = substrate
    }
    
    public func setCode(
        code: Data, extra: S.R.TExtrinsic.SigningPayload.Extra,
        with account: S.R.TAccountId, timeout: TimeInterval? = nil,
        _ cb: @escaping SExtrinsicApiCallback<S.R.THash, S.R>
    ) {
        signAndSubmit(call: SystemSetCodeCall<S.R>(code: code), extra: extra, with: account, timeout: timeout, cb)
    }
}

extension SubstrateExtrinsicSystemApi where S.R: ExtrinsicExtraProvider {
    public func setCode(
        code: Data, with account: S.R.TAccountId,
        options: S.R.TExtraOptions, timeout: TimeInterval? = nil,
        _ cb: @escaping SExtrinsicApiCallback<S.R.THash, S.R>
    ) {
        signAndSubmit(call: SystemSetCodeCall<S.R>(code: code), with: account,
                      options: options, timeout: timeout, cb)
    }
}

extension SubstrateExtrinsicSystemApi where S.R: DefaultExtrinsicExtraProvider {
    public func setCode(
        code: Data, with account: S.R.TAccountId,
        timeout: TimeInterval? = nil,
        _ cb: @escaping SExtrinsicApiCallback<S.R.THash, S.R>
    ) {
        signAndSubmit(call: SystemSetCodeCall<S.R>(code: code),
                      with: account, timeout: timeout, cb)
    }
}

extension SubstrateExtrinsicApiRegistry {
    public var system: SubstrateExtrinsicSystemApi<S> { getExtrinsicApi(SubstrateExtrinsicSystemApi<S>.self) }
}
