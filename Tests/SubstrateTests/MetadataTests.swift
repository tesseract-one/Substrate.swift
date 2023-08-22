//
//  MetadataTests.swift
//  
//
//  Created by Yehor Popovych on 28/06/2023.
//

import XCTest
import ScaleCodec
@testable import Substrate

final class MetadataTests: XCTestCase {
    func testEncDecV14() throws {
        let data = Resources.inst.metadadav14()
        let opaq = try ScaleCodec.decode(Optional<OpaqueMetadata>.self, from: data)!
        let metadata = try ScaleCodec.decode(VersionedNetworkMetadata.self, from: opaq.raw)
        XCTAssertEqual(metadata.metadata.version, 14)
        let enc = try ScaleCodec.encode(metadata)
        XCTAssertEqual(opaq.raw.hex(), enc.hex())
    }
    
    func testEncDecV15() throws {
        let data = Resources.inst.metadadav15()
        let opaq = try ScaleCodec.decode(Optional<OpaqueMetadata>.self, from: data)!
        let metadata = try ScaleCodec.decode(VersionedNetworkMetadata.self, from: opaq.raw)
        XCTAssertEqual(metadata.metadata.version, 15)
        let enc = try ScaleCodec.encode(metadata)
        XCTAssertEqual(opaq.raw.hex(), enc.hex())
    }
}
