//
//  File.swift
//  
//
//  Created by Yehor Popovych on 10/10/20.
//

import Foundation
import ScaleCodec

public struct EventRecord<H: Hash>: ScaleDynamicDecodable {
    public enum Phase {
        // Applying an extrinsic.
        case applyExtrinsic(UInt32)
        // Finalizing the block.
        case finalization
        // Initializing the block.
        case initialization
    }
    let phase: Phase
    let event: AnyEvent
    let topics: [H]
}

extension EventRecord.Phase: ScaleDecodable {
    public init(from decoder: ScaleDecoder) throws {
        let opt = try decoder.decode(.enumCaseId)
        switch opt {
        case 0: self = try .applyExtrinsic(decoder.decode())
        case 1: self = .finalization
        case 2: self = .initialization
        default: throw decoder.enumCaseError(for: opt)
        }
    }
}

extension EventRecord {
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        self.phase = try decoder.decode()
        self.event = try registry.decode(eventFrom: decoder)
        self.topics = try decoder.decode()
    }
}
