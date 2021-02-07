//
//  ExtrinsicProtocols.swift
//  
//
//  Created by Yehor Popovych on 2/6/21.
//

import Foundation

public protocol ExtrinsicProtocol: ScaleDynamicCodable {
    associatedtype Call: AnyCall
    associatedtype SignaturePayload: ScaleDynamicCodable
    
    var isSigned: Optional<Bool> { get }
    
    init(call: Self.Call, payload: Optional<SignaturePayload>)
    init(data: Data, registry: TypeRegistryProtocol) throws
    
    func opaque(registry: TypeRegistryProtocol) throws -> OpaqueExtrinsic
}

public protocol ExtrinsicMetadataProtocol {
    associatedtype SignedExtensions: SignedExtension
    
    var version: UInt8 { get }
    static var VERSION: UInt8 { get }
}

extension ExtrinsicMetadataProtocol {
    public var version: UInt8 { Self.VERSION }
}
