//
//  Tuples+RuntimeCodable.swift
//  
//
//  Created by Yehor Popovych on 26/07/2023.
//

import Foundation
import ScaleCodec

extension Tuple0: RuntimeCodable, RuntimeDynamicCodable {}

public extension ListTuple where DroppedLast: RuntimeDecodable, Last: RuntimeDecodable {
    init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: Runtime) throws {
        let prefix = try DroppedLast(from: &decoder, runtime: runtime)
        let last = try Last(from: &decoder, runtime: runtime)
        self.init(first: prefix, last: last)
    }
}

public extension ListTuple where DroppedLast: RuntimeEncodable, Last: RuntimeEncodable {
    func encode<E: ScaleCodec.Encoder>(in encoder: inout E, runtime: Runtime) throws {
        try dropLast.encode(in: &encoder, runtime: runtime)
        try last.encode(in: &encoder, runtime: runtime)
    }
}

extension Tuple1: RuntimeDecodable where T1: RuntimeDecodable {}
extension Tuple1: RuntimeEncodable where T1: RuntimeEncodable {}

extension Tuple2: RuntimeDecodable where T1: RuntimeDecodable, T2: RuntimeDecodable {}
extension Tuple2: RuntimeEncodable where T1: RuntimeEncodable, T2: RuntimeEncodable {}

extension Tuple3: RuntimeDecodable where
    T1: RuntimeDecodable, T2: RuntimeDecodable, T3: RuntimeDecodable {}
extension Tuple3: RuntimeEncodable where
    T1: RuntimeEncodable, T2: RuntimeEncodable, T3: RuntimeEncodable {}

extension Tuple4: RuntimeDecodable where
    T1: RuntimeDecodable, T2: RuntimeDecodable, T3: RuntimeDecodable,
    T4: RuntimeDecodable {}
extension Tuple4: RuntimeEncodable where
    T1: RuntimeEncodable, T2: RuntimeEncodable, T3: RuntimeEncodable,
    T4: RuntimeEncodable {}

extension Tuple5: RuntimeDecodable where
    T1: RuntimeDecodable, T2: RuntimeDecodable, T3: RuntimeDecodable,
    T4: RuntimeDecodable, T5: RuntimeDecodable {}
extension Tuple5: RuntimeEncodable where
    T1: RuntimeEncodable, T2: RuntimeEncodable, T3: RuntimeEncodable,
    T4: RuntimeEncodable, T5: RuntimeEncodable {}

extension Tuple6: RuntimeDecodable where
    T1: RuntimeDecodable, T2: RuntimeDecodable, T3: RuntimeDecodable,
    T4: RuntimeDecodable, T5: RuntimeDecodable, T6: RuntimeDecodable {}
extension Tuple6: RuntimeEncodable where
    T1: RuntimeEncodable, T2: RuntimeEncodable, T3: RuntimeEncodable,
    T4: RuntimeEncodable, T5: RuntimeEncodable, T6: RuntimeEncodable {}

extension Tuple7: RuntimeDecodable where
    T1: RuntimeDecodable, T2: RuntimeDecodable, T3: RuntimeDecodable,
    T4: RuntimeDecodable, T5: RuntimeDecodable, T6: RuntimeDecodable,
    T7: RuntimeDecodable {}
extension Tuple7: RuntimeEncodable where
    T1: RuntimeEncodable, T2: RuntimeEncodable, T3: RuntimeEncodable,
    T4: RuntimeEncodable, T5: RuntimeEncodable, T6: RuntimeEncodable,
    T7: RuntimeEncodable {}

extension Tuple8: RuntimeDecodable where
    T1: RuntimeDecodable, T2: RuntimeDecodable, T3: RuntimeDecodable,
    T4: RuntimeDecodable, T5: RuntimeDecodable, T6: RuntimeDecodable,
    T7: RuntimeDecodable, T8: RuntimeDecodable {}
extension Tuple8: RuntimeEncodable where
    T1: RuntimeEncodable, T2: RuntimeEncodable, T3: RuntimeEncodable,
    T4: RuntimeEncodable, T5: RuntimeEncodable, T6: RuntimeEncodable,
    T7: RuntimeEncodable, T8: RuntimeEncodable {}

extension Tuple9: RuntimeDecodable where
    T1: RuntimeDecodable, T2: RuntimeDecodable, T3: RuntimeDecodable,
    T4: RuntimeDecodable, T5: RuntimeDecodable, T6: RuntimeDecodable,
    T7: RuntimeDecodable, T8: RuntimeDecodable, T9: RuntimeDecodable {}
extension Tuple9: RuntimeEncodable where
    T1: RuntimeEncodable, T2: RuntimeEncodable, T3: RuntimeEncodable,
    T4: RuntimeEncodable, T5: RuntimeEncodable, T6: RuntimeEncodable,
    T7: RuntimeEncodable, T8: RuntimeEncodable, T9: RuntimeEncodable {}

extension Tuple10: RuntimeDecodable where
    T1: RuntimeDecodable, T2: RuntimeDecodable, T3: RuntimeDecodable,
    T4: RuntimeDecodable, T5: RuntimeDecodable, T6: RuntimeDecodable,
    T7: RuntimeDecodable, T8: RuntimeDecodable, T9: RuntimeDecodable,
    T10: RuntimeDecodable {}
extension Tuple10: RuntimeEncodable where
    T1: RuntimeEncodable, T2: RuntimeEncodable, T3: RuntimeEncodable,
    T4: RuntimeEncodable, T5: RuntimeEncodable, T6: RuntimeEncodable,
    T7: RuntimeEncodable, T8: RuntimeEncodable, T9: RuntimeEncodable,
    T10: RuntimeEncodable {}

extension Tuple11: RuntimeDecodable where
    T1: RuntimeDecodable, T2: RuntimeDecodable, T3: RuntimeDecodable,
    T4: RuntimeDecodable, T5: RuntimeDecodable, T6: RuntimeDecodable,
    T7: RuntimeDecodable, T8: RuntimeDecodable, T9: RuntimeDecodable,
    T10: RuntimeDecodable, T11: RuntimeDecodable {}
extension Tuple11: RuntimeEncodable where
    T1: RuntimeEncodable, T2: RuntimeEncodable, T3: RuntimeEncodable,
    T4: RuntimeEncodable, T5: RuntimeEncodable, T6: RuntimeEncodable,
    T7: RuntimeEncodable, T8: RuntimeEncodable, T9: RuntimeEncodable,
    T10: RuntimeEncodable, T11: RuntimeEncodable {}

extension Tuple12: RuntimeDecodable where
    T1: RuntimeDecodable, T2: RuntimeDecodable, T3: RuntimeDecodable,
    T4: RuntimeDecodable, T5: RuntimeDecodable, T6: RuntimeDecodable,
    T7: RuntimeDecodable, T8: RuntimeDecodable, T9: RuntimeDecodable,
    T10: RuntimeDecodable, T11: RuntimeDecodable, T12: RuntimeDecodable {}
extension Tuple12: RuntimeEncodable where
    T1: RuntimeEncodable, T2: RuntimeEncodable, T3: RuntimeEncodable,
    T4: RuntimeEncodable, T5: RuntimeEncodable, T6: RuntimeEncodable,
    T7: RuntimeEncodable, T8: RuntimeEncodable, T9: RuntimeEncodable,
    T10: RuntimeEncodable, T11: RuntimeEncodable, T12: RuntimeEncodable {}

extension Tuple13: RuntimeDecodable where
    T1: RuntimeDecodable, T2: RuntimeDecodable, T3: RuntimeDecodable,
    T4: RuntimeDecodable, T5: RuntimeDecodable, T6: RuntimeDecodable,
    T7: RuntimeDecodable, T8: RuntimeDecodable, T9: RuntimeDecodable,
    T10: RuntimeDecodable, T11: RuntimeDecodable, T12: RuntimeDecodable,
    T13: RuntimeDecodable {}
extension Tuple13: RuntimeEncodable where
    T1: RuntimeEncodable, T2: RuntimeEncodable, T3: RuntimeEncodable,
    T4: RuntimeEncodable, T5: RuntimeEncodable, T6: RuntimeEncodable,
    T7: RuntimeEncodable, T8: RuntimeEncodable, T9: RuntimeEncodable,
    T10: RuntimeEncodable, T11: RuntimeEncodable, T12: RuntimeEncodable,
    T13: RuntimeEncodable {}

extension Tuple14: RuntimeDecodable where
    T1: RuntimeDecodable, T2: RuntimeDecodable, T3: RuntimeDecodable,
    T4: RuntimeDecodable, T5: RuntimeDecodable, T6: RuntimeDecodable,
    T7: RuntimeDecodable, T8: RuntimeDecodable, T9: RuntimeDecodable,
    T10: RuntimeDecodable, T11: RuntimeDecodable, T12: RuntimeDecodable,
    T13: RuntimeDecodable, T14: RuntimeDecodable {}
extension Tuple14: RuntimeEncodable where
    T1: RuntimeEncodable, T2: RuntimeEncodable, T3: RuntimeEncodable,
    T4: RuntimeEncodable, T5: RuntimeEncodable, T6: RuntimeEncodable,
    T7: RuntimeEncodable, T8: RuntimeEncodable, T9: RuntimeEncodable,
    T10: RuntimeEncodable, T11: RuntimeEncodable, T12: RuntimeEncodable,
    T13: RuntimeEncodable, T14: RuntimeEncodable {}

extension Tuple15: RuntimeDecodable where
    T1: RuntimeDecodable, T2: RuntimeDecodable, T3: RuntimeDecodable,
    T4: RuntimeDecodable, T5: RuntimeDecodable, T6: RuntimeDecodable,
    T7: RuntimeDecodable, T8: RuntimeDecodable, T9: RuntimeDecodable,
    T10: RuntimeDecodable, T11: RuntimeDecodable, T12: RuntimeDecodable,
    T13: RuntimeDecodable, T14: RuntimeDecodable, T15: RuntimeDecodable {}
extension Tuple15: RuntimeEncodable where
    T1: RuntimeEncodable, T2: RuntimeEncodable, T3: RuntimeEncodable,
    T4: RuntimeEncodable, T5: RuntimeEncodable, T6: RuntimeEncodable,
    T7: RuntimeEncodable, T8: RuntimeEncodable, T9: RuntimeEncodable,
    T10: RuntimeEncodable, T11: RuntimeEncodable, T12: RuntimeEncodable,
    T13: RuntimeEncodable, T14: RuntimeEncodable, T15: RuntimeEncodable {}
