//
//  DynamicTypesLookupTests.swift
//  
//
//  Created by Yehor Popovych on 28/06/2023.
//

import XCTest
import ScaleCodec
@testable import Substrate

final class DynamicTypesLookupTests: XCTestCase {
    func testMetadataV14() throws {
        try metadataTest(data: Resources.inst.metadadav14(), is14: true)
    }
    
    func testMetadataV15() throws {
        try metadataTest(data: Resources.inst.metadadav15(), is14: false)
    }
    
    func metadataTest(data: Data, is14: Bool) throws {
        let opaq = try ScaleCodec.decode(Optional<OpaqueMetadata>.self, from: data)!
        let metadata = try ScaleCodec.decode(VersionedNetworkMetadata.self, from: opaq.raw).metadata.asMetadata()
        let config = try Configs.Dynamic()
        
        let _ = try config.hashType(metadata: metadata)
        let _ = try config.hasher(metadata: metadata)
        let _ = try config.eventType(metadata: metadata)
        let _ = try config.dispatchErrorType(metadata: metadata)
        let ext = try config.extrinsicTypes(metadata: metadata)
        let _ = try config.accountType(metadata: metadata, address: ext.addr)
        if !is14 {
            let _ = try config.blockType(metadata: metadata)
            let _ = try config.transactionValidityErrorType(metadata: metadata)
        }
    }
}
