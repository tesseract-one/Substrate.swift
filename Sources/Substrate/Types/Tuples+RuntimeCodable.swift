//
//  Tuples+RuntimeCodable.swift
//  
//
//  Created by Yehor Popovych on 26/07/2023.
//

import Foundation
import ScaleCodec

extension Tuple0: RuntimeCodable {}

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

extension Tuple1: RuntimeLazyDynamicDecodable where T1: RuntimeLazyDynamicDecodable {}
extension Tuple1: RuntimeDecodable where T1: RuntimeDecodable {}
extension Tuple1: RuntimeLazyDynamicEncodable where T1: RuntimeLazyDynamicEncodable {}
extension Tuple1: RuntimeEncodable where T1: RuntimeEncodable {}

extension Tuple2: RuntimeLazyDynamicDecodable where
    T1: RuntimeLazyDynamicDecodable, T2: RuntimeLazyDynamicDecodable {}
extension Tuple2: RuntimeDecodable where T1: RuntimeDecodable, T2: RuntimeDecodable {}
extension Tuple2: RuntimeLazyDynamicEncodable where
    T1: RuntimeLazyDynamicEncodable, T2: RuntimeLazyDynamicEncodable {}
extension Tuple2: RuntimeEncodable where T1: RuntimeEncodable, T2: RuntimeEncodable {}

extension Tuple3: RuntimeLazyDynamicDecodable where
    T1: RuntimeLazyDynamicDecodable, T2: RuntimeLazyDynamicDecodable,
    T3: RuntimeLazyDynamicDecodable {}
extension Tuple3: RuntimeDecodable where
    T1: RuntimeDecodable, T2: RuntimeDecodable, T3: RuntimeDecodable {}

extension Tuple3: RuntimeLazyDynamicEncodable where
    T1: RuntimeLazyDynamicEncodable, T2: RuntimeLazyDynamicEncodable,
    T3: RuntimeLazyDynamicEncodable {}
extension Tuple3: RuntimeEncodable where
    T1: RuntimeEncodable, T2: RuntimeEncodable, T3: RuntimeEncodable {}

extension Tuple4: RuntimeLazyDynamicDecodable where
    T1: RuntimeLazyDynamicDecodable, T2: RuntimeLazyDynamicDecodable,
    T3: RuntimeLazyDynamicDecodable, T4: RuntimeLazyDynamicDecodable {}
extension Tuple4: RuntimeDecodable where
    T1: RuntimeDecodable, T2: RuntimeDecodable, T3: RuntimeDecodable,
    T4: RuntimeDecodable {}
extension Tuple4: RuntimeLazyDynamicEncodable where
    T1: RuntimeLazyDynamicEncodable, T2: RuntimeLazyDynamicEncodable,
    T3: RuntimeLazyDynamicEncodable, T4: RuntimeLazyDynamicEncodable {}
extension Tuple4: RuntimeEncodable where
    T1: RuntimeEncodable, T2: RuntimeEncodable, T3: RuntimeEncodable,
    T4: RuntimeEncodable {}

extension Tuple5: RuntimeLazyDynamicDecodable where
    T1: RuntimeLazyDynamicDecodable, T2: RuntimeLazyDynamicDecodable,
    T3: RuntimeLazyDynamicDecodable, T4: RuntimeLazyDynamicDecodable,
    T5: RuntimeLazyDynamicDecodable {}
extension Tuple5: RuntimeDecodable where
    T1: RuntimeDecodable, T2: RuntimeDecodable, T3: RuntimeDecodable,
    T4: RuntimeDecodable, T5: RuntimeDecodable {}
extension Tuple5: RuntimeLazyDynamicEncodable where
    T1: RuntimeLazyDynamicEncodable, T2: RuntimeLazyDynamicEncodable,
    T3: RuntimeLazyDynamicEncodable, T4: RuntimeLazyDynamicEncodable,
    T5: RuntimeLazyDynamicEncodable {}
extension Tuple5: RuntimeEncodable where
    T1: RuntimeEncodable, T2: RuntimeEncodable, T3: RuntimeEncodable,
    T4: RuntimeEncodable, T5: RuntimeEncodable {}

extension Tuple6: RuntimeLazyDynamicDecodable where
    T1: RuntimeLazyDynamicDecodable, T2: RuntimeLazyDynamicDecodable,
    T3: RuntimeLazyDynamicDecodable, T4: RuntimeLazyDynamicDecodable,
    T5: RuntimeLazyDynamicDecodable, T6: RuntimeLazyDynamicDecodable {}
extension Tuple6: RuntimeDecodable where
    T1: RuntimeDecodable, T2: RuntimeDecodable, T3: RuntimeDecodable,
    T4: RuntimeDecodable, T5: RuntimeDecodable, T6: RuntimeDecodable {}
extension Tuple6: RuntimeLazyDynamicEncodable where
    T1: RuntimeLazyDynamicEncodable, T2: RuntimeLazyDynamicEncodable,
    T3: RuntimeLazyDynamicEncodable, T4: RuntimeLazyDynamicEncodable,
    T5: RuntimeLazyDynamicEncodable, T6: RuntimeLazyDynamicEncodable {}
extension Tuple6: RuntimeEncodable where
    T1: RuntimeEncodable, T2: RuntimeEncodable, T3: RuntimeEncodable,
    T4: RuntimeEncodable, T5: RuntimeEncodable, T6: RuntimeEncodable {}

extension Tuple7: RuntimeLazyDynamicDecodable where
    T1: RuntimeLazyDynamicDecodable, T2: RuntimeLazyDynamicDecodable,
    T3: RuntimeLazyDynamicDecodable, T4: RuntimeLazyDynamicDecodable,
    T5: RuntimeLazyDynamicDecodable, T6: RuntimeLazyDynamicDecodable,
    T7: RuntimeLazyDynamicDecodable {}
extension Tuple7: RuntimeDecodable where
    T1: RuntimeDecodable, T2: RuntimeDecodable, T3: RuntimeDecodable,
    T4: RuntimeDecodable, T5: RuntimeDecodable, T6: RuntimeDecodable,
    T7: RuntimeDecodable {}
extension Tuple7: RuntimeLazyDynamicEncodable where
    T1: RuntimeLazyDynamicEncodable, T2: RuntimeLazyDynamicEncodable,
    T3: RuntimeLazyDynamicEncodable, T4: RuntimeLazyDynamicEncodable,
    T5: RuntimeLazyDynamicEncodable, T6: RuntimeLazyDynamicEncodable,
    T7: RuntimeLazyDynamicEncodable {}
extension Tuple7: RuntimeEncodable where
    T1: RuntimeEncodable, T2: RuntimeEncodable, T3: RuntimeEncodable,
    T4: RuntimeEncodable, T5: RuntimeEncodable, T6: RuntimeEncodable,
    T7: RuntimeEncodable {}

extension Tuple8: RuntimeLazyDynamicDecodable where
    T1: RuntimeLazyDynamicDecodable, T2: RuntimeLazyDynamicDecodable,
    T3: RuntimeLazyDynamicDecodable, T4: RuntimeLazyDynamicDecodable,
    T5: RuntimeLazyDynamicDecodable, T6: RuntimeLazyDynamicDecodable,
    T7: RuntimeLazyDynamicDecodable, T8: RuntimeLazyDynamicDecodable {}
extension Tuple8: RuntimeDecodable where
    T1: RuntimeDecodable, T2: RuntimeDecodable, T3: RuntimeDecodable,
    T4: RuntimeDecodable, T5: RuntimeDecodable, T6: RuntimeDecodable,
    T7: RuntimeDecodable, T8: RuntimeDecodable {}
extension Tuple8: RuntimeLazyDynamicEncodable where
    T1: RuntimeLazyDynamicEncodable, T2: RuntimeLazyDynamicEncodable,
    T3: RuntimeLazyDynamicEncodable, T4: RuntimeLazyDynamicEncodable,
    T5: RuntimeLazyDynamicEncodable, T6: RuntimeLazyDynamicEncodable,
    T7: RuntimeLazyDynamicEncodable, T8: RuntimeLazyDynamicEncodable {}
extension Tuple8: RuntimeEncodable where
    T1: RuntimeEncodable, T2: RuntimeEncodable, T3: RuntimeEncodable,
    T4: RuntimeEncodable, T5: RuntimeEncodable, T6: RuntimeEncodable,
    T7: RuntimeEncodable, T8: RuntimeEncodable {}

extension Tuple9: RuntimeLazyDynamicDecodable where
    T1: RuntimeLazyDynamicDecodable, T2: RuntimeLazyDynamicDecodable,
    T3: RuntimeLazyDynamicDecodable, T4: RuntimeLazyDynamicDecodable,
    T5: RuntimeLazyDynamicDecodable, T6: RuntimeLazyDynamicDecodable,
    T7: RuntimeLazyDynamicDecodable, T8: RuntimeLazyDynamicDecodable,
    T9: RuntimeLazyDynamicDecodable {}
extension Tuple9: RuntimeDecodable where
    T1: RuntimeDecodable, T2: RuntimeDecodable, T3: RuntimeDecodable,
    T4: RuntimeDecodable, T5: RuntimeDecodable, T6: RuntimeDecodable,
    T7: RuntimeDecodable, T8: RuntimeDecodable, T9: RuntimeDecodable {}
extension Tuple9: RuntimeLazyDynamicEncodable where
    T1: RuntimeLazyDynamicEncodable, T2: RuntimeLazyDynamicEncodable,
    T3: RuntimeLazyDynamicEncodable, T4: RuntimeLazyDynamicEncodable,
    T5: RuntimeLazyDynamicEncodable, T6: RuntimeLazyDynamicEncodable,
    T7: RuntimeLazyDynamicEncodable, T8: RuntimeLazyDynamicEncodable,
    T9: RuntimeLazyDynamicEncodable {}
extension Tuple9: RuntimeEncodable where
    T1: RuntimeEncodable, T2: RuntimeEncodable, T3: RuntimeEncodable,
    T4: RuntimeEncodable, T5: RuntimeEncodable, T6: RuntimeEncodable,
    T7: RuntimeEncodable, T8: RuntimeEncodable, T9: RuntimeEncodable {}

extension Tuple10: RuntimeLazyDynamicDecodable where
    T1: RuntimeLazyDynamicDecodable, T2: RuntimeLazyDynamicDecodable,
    T3: RuntimeLazyDynamicDecodable, T4: RuntimeLazyDynamicDecodable,
    T5: RuntimeLazyDynamicDecodable, T6: RuntimeLazyDynamicDecodable,
    T7: RuntimeLazyDynamicDecodable, T8: RuntimeLazyDynamicDecodable,
    T9: RuntimeLazyDynamicDecodable, T10: RuntimeLazyDynamicDecodable {}
extension Tuple10: RuntimeDecodable where
    T1: RuntimeDecodable, T2: RuntimeDecodable, T3: RuntimeDecodable,
    T4: RuntimeDecodable, T5: RuntimeDecodable, T6: RuntimeDecodable,
    T7: RuntimeDecodable, T8: RuntimeDecodable, T9: RuntimeDecodable,
    T10: RuntimeDecodable {}
extension Tuple10: RuntimeLazyDynamicEncodable where
    T1: RuntimeLazyDynamicEncodable, T2: RuntimeLazyDynamicEncodable,
    T3: RuntimeLazyDynamicEncodable, T4: RuntimeLazyDynamicEncodable,
    T5: RuntimeLazyDynamicEncodable, T6: RuntimeLazyDynamicEncodable,
    T7: RuntimeLazyDynamicEncodable, T8: RuntimeLazyDynamicEncodable,
    T9: RuntimeLazyDynamicEncodable, T10: RuntimeLazyDynamicEncodable {}
extension Tuple10: RuntimeEncodable where
    T1: RuntimeEncodable, T2: RuntimeEncodable, T3: RuntimeEncodable,
    T4: RuntimeEncodable, T5: RuntimeEncodable, T6: RuntimeEncodable,
    T7: RuntimeEncodable, T8: RuntimeEncodable, T9: RuntimeEncodable,
    T10: RuntimeEncodable {}

extension Tuple11: RuntimeLazyDynamicDecodable where
    T1: RuntimeLazyDynamicDecodable, T2: RuntimeLazyDynamicDecodable,
    T3: RuntimeLazyDynamicDecodable, T4: RuntimeLazyDynamicDecodable,
    T5: RuntimeLazyDynamicDecodable, T6: RuntimeLazyDynamicDecodable,
    T7: RuntimeLazyDynamicDecodable, T8: RuntimeLazyDynamicDecodable,
    T9: RuntimeLazyDynamicDecodable, T10: RuntimeLazyDynamicDecodable,
    T11: RuntimeLazyDynamicDecodable {}
extension Tuple11: RuntimeDecodable where
    T1: RuntimeDecodable, T2: RuntimeDecodable, T3: RuntimeDecodable,
    T4: RuntimeDecodable, T5: RuntimeDecodable, T6: RuntimeDecodable,
    T7: RuntimeDecodable, T8: RuntimeDecodable, T9: RuntimeDecodable,
    T10: RuntimeDecodable, T11: RuntimeDecodable {}
extension Tuple11: RuntimeLazyDynamicEncodable where
    T1: RuntimeLazyDynamicEncodable, T2: RuntimeLazyDynamicEncodable,
    T3: RuntimeLazyDynamicEncodable, T4: RuntimeLazyDynamicEncodable,
    T5: RuntimeLazyDynamicEncodable, T6: RuntimeLazyDynamicEncodable,
    T7: RuntimeLazyDynamicEncodable, T8: RuntimeLazyDynamicEncodable,
    T9: RuntimeLazyDynamicEncodable, T10: RuntimeLazyDynamicEncodable,
    T11: RuntimeLazyDynamicEncodable {}
extension Tuple11: RuntimeEncodable where
    T1: RuntimeEncodable, T2: RuntimeEncodable, T3: RuntimeEncodable,
    T4: RuntimeEncodable, T5: RuntimeEncodable, T6: RuntimeEncodable,
    T7: RuntimeEncodable, T8: RuntimeEncodable, T9: RuntimeEncodable,
    T10: RuntimeEncodable, T11: RuntimeEncodable {}

extension Tuple12: RuntimeLazyDynamicDecodable where
    T1: RuntimeLazyDynamicDecodable, T2: RuntimeLazyDynamicDecodable,
    T3: RuntimeLazyDynamicDecodable, T4: RuntimeLazyDynamicDecodable,
    T5: RuntimeLazyDynamicDecodable, T6: RuntimeLazyDynamicDecodable,
    T7: RuntimeLazyDynamicDecodable, T8: RuntimeLazyDynamicDecodable,
    T9: RuntimeLazyDynamicDecodable, T10: RuntimeLazyDynamicDecodable,
    T11: RuntimeLazyDynamicDecodable, T12: RuntimeLazyDynamicDecodable {}
extension Tuple12: RuntimeDecodable where
    T1: RuntimeDecodable, T2: RuntimeDecodable, T3: RuntimeDecodable,
    T4: RuntimeDecodable, T5: RuntimeDecodable, T6: RuntimeDecodable,
    T7: RuntimeDecodable, T8: RuntimeDecodable, T9: RuntimeDecodable,
    T10: RuntimeDecodable, T11: RuntimeDecodable, T12: RuntimeDecodable {}
extension Tuple12: RuntimeLazyDynamicEncodable where
    T1: RuntimeLazyDynamicEncodable, T2: RuntimeLazyDynamicEncodable,
    T3: RuntimeLazyDynamicEncodable, T4: RuntimeLazyDynamicEncodable,
    T5: RuntimeLazyDynamicEncodable, T6: RuntimeLazyDynamicEncodable,
    T7: RuntimeLazyDynamicEncodable, T8: RuntimeLazyDynamicEncodable,
    T9: RuntimeLazyDynamicEncodable, T10: RuntimeLazyDynamicEncodable,
    T11: RuntimeLazyDynamicEncodable, T12: RuntimeLazyDynamicEncodable {}
extension Tuple12: RuntimeEncodable where
    T1: RuntimeEncodable, T2: RuntimeEncodable, T3: RuntimeEncodable,
    T4: RuntimeEncodable, T5: RuntimeEncodable, T6: RuntimeEncodable,
    T7: RuntimeEncodable, T8: RuntimeEncodable, T9: RuntimeEncodable,
    T10: RuntimeEncodable, T11: RuntimeEncodable, T12: RuntimeEncodable {}

extension Tuple13: RuntimeLazyDynamicDecodable where
    T1: RuntimeLazyDynamicDecodable, T2: RuntimeLazyDynamicDecodable,
    T3: RuntimeLazyDynamicDecodable, T4: RuntimeLazyDynamicDecodable,
    T5: RuntimeLazyDynamicDecodable, T6: RuntimeLazyDynamicDecodable,
    T7: RuntimeLazyDynamicDecodable, T8: RuntimeLazyDynamicDecodable,
    T9: RuntimeLazyDynamicDecodable, T10: RuntimeLazyDynamicDecodable,
    T11: RuntimeLazyDynamicDecodable, T12: RuntimeLazyDynamicDecodable,
    T13: RuntimeLazyDynamicDecodable {}
extension Tuple13: RuntimeDecodable where
    T1: RuntimeDecodable, T2: RuntimeDecodable, T3: RuntimeDecodable,
    T4: RuntimeDecodable, T5: RuntimeDecodable, T6: RuntimeDecodable,
    T7: RuntimeDecodable, T8: RuntimeDecodable, T9: RuntimeDecodable,
    T10: RuntimeDecodable, T11: RuntimeDecodable, T12: RuntimeDecodable,
    T13: RuntimeDecodable {}
extension Tuple13: RuntimeLazyDynamicEncodable where
    T1: RuntimeLazyDynamicEncodable, T2: RuntimeLazyDynamicEncodable,
    T3: RuntimeLazyDynamicEncodable, T4: RuntimeLazyDynamicEncodable,
    T5: RuntimeLazyDynamicEncodable, T6: RuntimeLazyDynamicEncodable,
    T7: RuntimeLazyDynamicEncodable, T8: RuntimeLazyDynamicEncodable,
    T9: RuntimeLazyDynamicEncodable, T10: RuntimeLazyDynamicEncodable,
    T11: RuntimeLazyDynamicEncodable, T12: RuntimeLazyDynamicEncodable,
    T13: RuntimeLazyDynamicEncodable {}
extension Tuple13: RuntimeEncodable where
    T1: RuntimeEncodable, T2: RuntimeEncodable, T3: RuntimeEncodable,
    T4: RuntimeEncodable, T5: RuntimeEncodable, T6: RuntimeEncodable,
    T7: RuntimeEncodable, T8: RuntimeEncodable, T9: RuntimeEncodable,
    T10: RuntimeEncodable, T11: RuntimeEncodable, T12: RuntimeEncodable,
    T13: RuntimeEncodable {}

extension Tuple14: RuntimeLazyDynamicDecodable where
    T1: RuntimeLazyDynamicDecodable, T2: RuntimeLazyDynamicDecodable,
    T3: RuntimeLazyDynamicDecodable, T4: RuntimeLazyDynamicDecodable,
    T5: RuntimeLazyDynamicDecodable, T6: RuntimeLazyDynamicDecodable,
    T7: RuntimeLazyDynamicDecodable, T8: RuntimeLazyDynamicDecodable,
    T9: RuntimeLazyDynamicDecodable, T10: RuntimeLazyDynamicDecodable,
    T11: RuntimeLazyDynamicDecodable, T12: RuntimeLazyDynamicDecodable,
    T13: RuntimeLazyDynamicDecodable, T14: RuntimeLazyDynamicDecodable {}
extension Tuple14: RuntimeDecodable where
    T1: RuntimeDecodable, T2: RuntimeDecodable, T3: RuntimeDecodable,
    T4: RuntimeDecodable, T5: RuntimeDecodable, T6: RuntimeDecodable,
    T7: RuntimeDecodable, T8: RuntimeDecodable, T9: RuntimeDecodable,
    T10: RuntimeDecodable, T11: RuntimeDecodable, T12: RuntimeDecodable,
    T13: RuntimeDecodable, T14: RuntimeDecodable {}
extension Tuple14: RuntimeLazyDynamicEncodable where
    T1: RuntimeLazyDynamicEncodable, T2: RuntimeLazyDynamicEncodable,
    T3: RuntimeLazyDynamicEncodable, T4: RuntimeLazyDynamicEncodable,
    T5: RuntimeLazyDynamicEncodable, T6: RuntimeLazyDynamicEncodable,
    T7: RuntimeLazyDynamicEncodable, T8: RuntimeLazyDynamicEncodable,
    T9: RuntimeLazyDynamicEncodable, T10: RuntimeLazyDynamicEncodable,
    T11: RuntimeLazyDynamicEncodable, T12: RuntimeLazyDynamicEncodable,
    T13: RuntimeLazyDynamicEncodable, T14: RuntimeLazyDynamicEncodable {}
extension Tuple14: RuntimeEncodable where
    T1: RuntimeEncodable, T2: RuntimeEncodable, T3: RuntimeEncodable,
    T4: RuntimeEncodable, T5: RuntimeEncodable, T6: RuntimeEncodable,
    T7: RuntimeEncodable, T8: RuntimeEncodable, T9: RuntimeEncodable,
    T10: RuntimeEncodable, T11: RuntimeEncodable, T12: RuntimeEncodable,
    T13: RuntimeEncodable, T14: RuntimeEncodable {}

extension Tuple15: RuntimeLazyDynamicDecodable where
    T1: RuntimeLazyDynamicDecodable, T2: RuntimeLazyDynamicDecodable,
    T3: RuntimeLazyDynamicDecodable, T4: RuntimeLazyDynamicDecodable,
    T5: RuntimeLazyDynamicDecodable, T6: RuntimeLazyDynamicDecodable,
    T7: RuntimeLazyDynamicDecodable, T8: RuntimeLazyDynamicDecodable,
    T9: RuntimeLazyDynamicDecodable, T10: RuntimeLazyDynamicDecodable,
    T11: RuntimeLazyDynamicDecodable, T12: RuntimeLazyDynamicDecodable,
    T13: RuntimeLazyDynamicDecodable, T14: RuntimeLazyDynamicDecodable,
    T15: RuntimeLazyDynamicDecodable {}
extension Tuple15: RuntimeDecodable where
    T1: RuntimeDecodable, T2: RuntimeDecodable, T3: RuntimeDecodable,
    T4: RuntimeDecodable, T5: RuntimeDecodable, T6: RuntimeDecodable,
    T7: RuntimeDecodable, T8: RuntimeDecodable, T9: RuntimeDecodable,
    T10: RuntimeDecodable, T11: RuntimeDecodable, T12: RuntimeDecodable,
    T13: RuntimeDecodable, T14: RuntimeDecodable, T15: RuntimeDecodable {}
extension Tuple15: RuntimeLazyDynamicEncodable where
    T1: RuntimeLazyDynamicEncodable, T2: RuntimeLazyDynamicEncodable,
    T3: RuntimeLazyDynamicEncodable, T4: RuntimeLazyDynamicEncodable,
    T5: RuntimeLazyDynamicEncodable, T6: RuntimeLazyDynamicEncodable,
    T7: RuntimeLazyDynamicEncodable, T8: RuntimeLazyDynamicEncodable,
    T9: RuntimeLazyDynamicEncodable, T10: RuntimeLazyDynamicEncodable,
    T11: RuntimeLazyDynamicEncodable, T12: RuntimeLazyDynamicEncodable,
    T13: RuntimeLazyDynamicEncodable, T14: RuntimeLazyDynamicEncodable,
    T15: RuntimeLazyDynamicEncodable {}
extension Tuple15: RuntimeEncodable where
    T1: RuntimeEncodable, T2: RuntimeEncodable, T3: RuntimeEncodable,
    T4: RuntimeEncodable, T5: RuntimeEncodable, T6: RuntimeEncodable,
    T7: RuntimeEncodable, T8: RuntimeEncodable, T9: RuntimeEncodable,
    T10: RuntimeEncodable, T11: RuntimeEncodable, T12: RuntimeEncodable,
    T13: RuntimeEncodable, T14: RuntimeEncodable, T15: RuntimeEncodable {}
