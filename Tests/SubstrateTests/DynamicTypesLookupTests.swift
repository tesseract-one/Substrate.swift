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
        let config = Configs.Registry.dynamicBlake2.config
        let types = try config.dynamicTypes(metadata: metadata)
        let _ = try types.hash.get()
        let _ = try types.hasher.get()
        let _ = try types.account.get()
        let _ = try types.dispatchError.get()
        if !is14 {
            let _ = try types.block.get()
            let _ = try types.transactionValidityError.get()
        }
    }
}
