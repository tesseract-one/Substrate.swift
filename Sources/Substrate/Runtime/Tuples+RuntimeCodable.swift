//
//  Tuples+RuntimeCodable.swift
//  
//
//  Created by Yehor Popovych on 26/07/2023.
//

import Foundation
import ScaleCodec

extension Tuple0: RuntimeCodable, RuntimeDynamicCodable {}

public extension LinkedTuple where DroppedLast: RuntimeDecodable, Last: RuntimeDecodable {
    init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws {
        let prefix = try DroppedLast(from: &decoder, runtime: runtime)
        let last = try Last(from: &decoder, runtime: runtime)
        self.init(first: prefix, last: last)
    }
}

public extension LinkedTuple where DroppedLast: RuntimeEncodable, Last: RuntimeEncodable {
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
        try dropLast.encode(in: &encoder, runtime: runtime)
        try last.encode(in: &encoder, runtime: runtime)
    }
}

extension Tuple1: RuntimeDecodable where T1: RuntimeDecodable {}
extension Tuple1: RuntimeEncodable where T1: RuntimeEncodable {}

extension Tuple2: RuntimeDecodable where T1: RuntimeDecodable, T2: RuntimeDecodable {}
extension Tuple2: RuntimeEncodable where T1: RuntimeEncodable, T2: RuntimeEncodable {}
