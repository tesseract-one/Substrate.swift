//
//  ExtrinsicProtocols.swift
//  
//
//  Created by Yehor Popovych on 2/6/21.
//

import Foundation

public protocol ExtrinsicSigningPayloadProtocol: ScaleDynamicEncodable {
    associatedtype Extra: SignedExtension
    
    init(call: AnyCall, extra: Extra) throws
}

public protocol ExtrinsicSignatureProtocol: ScaleDynamicCodable {
    associatedtype AddressType: Address
    associatedtype SignatureType: Signature
}

public protocol ExtrinsicProtocol: ScaleDynamicCodable {
    associatedtype SigningPayload: ExtrinsicSigningPayloadProtocol
    associatedtype SignaturePayload: ExtrinsicSignatureProtocol
    
    var isSigned: Bool { get }
    var version: UInt8 { get }
    static var VERSION: UInt8 { get }
    
    init(call: AnyCall, signature: Optional<SignaturePayload>)
    init(payload: SigningPayload)
    
    func payload(with extra: SigningPayload.Extra) throws -> SigningPayload
    func signed(by address: SignaturePayload.AddressType,
                with signature: SignaturePayload.SignatureType,
                payload: SigningPayload) throws -> Self
}

extension ExtrinsicProtocol {
    public var version: UInt8 { Self.VERSION }
}
