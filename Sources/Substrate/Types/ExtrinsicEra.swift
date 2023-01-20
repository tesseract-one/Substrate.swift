//
//  ExtrinsicEra.swift
//  
//
//  Created by Yehor Popovych on 10/12/20.
//

import Foundation
import ScaleCodec

public enum ExtrinsicEra {
    case immortal
    case mortal(period: UInt64, phase: UInt64)
    
    var isImmortal: Bool {
        switch self {
        case .immortal: return true
        default: return false
        }
    }
    
    // Create a new era based on a period (which should be a power of two between 4 and 65536 inclusive)
    // and a block number on which it should start (or, for long periods, be shortly after the start).
    //
    // If using `Era` in the context of `FRAME` runtime, make sure that `period`
    // does not exceed `BlockHashCount` parameter passed to `system` module, since that
    // prunes old blocks and renders transactions immediately invalid.
    public init(period: UInt64, current: UInt64) {
        let period = min(max(period._nextPowerOfTwo ?? (1 << 16), 4), 1 << 16)
        let phase = current % period
        let quantize_factor = max(1, (period >> 12))
        let quantized_phase = phase / quantize_factor * quantize_factor
        self = .mortal(period: period, phase: quantized_phase)
    }
    
    // Get the block number of the start of the era whose properties this object
    // describes that `current` belongs to.
    public func birth(current: UInt64) -> UInt64 {
        switch self {
        case .immortal: return 0
        case .mortal(period: let period, phase: let phase): return (max(current, phase) - phase) / period * period + phase
        }
    }

    // Get the block number of the first block at which the era has ended.
    public func death(current: UInt64) -> UInt64 {
        switch self {
        case .immortal: return UInt64.max
        case .mortal(period: let period, phase: _): return self.birth(current: current) + period
        }
    }
    
    public init?(b1: UInt8, b2: UInt8?) {
        if b1 == 0 {
            guard b2 == nil else { return nil }
            self = .immortal
        } else {
            guard let b2 = b2 else { return nil}
            let encoded = UInt64(b1) + UInt64(b2) << 8
            let period = UInt64(2) << (encoded % (1 << 4))
            let quantize_factor = max((period >> 12), 1)
            let phase = (encoded >> 4) * quantize_factor
            guard period >= 4 && phase < period else { return nil }
            self = .mortal(period: period, phase: phase)
        }
    }
    
    public func serialize() -> (UInt8, UInt8?) {
        switch self {
        case .immortal: return (0, nil)
        case .mortal(period: let period, phase: let phase):
            let quantize_factor = max((period >> 12), 1)
            let encoded = UInt16(min(max(period.trailingZeroBitCount - 1, 1), 15))
                | UInt16((phase / quantize_factor) << 4)
            return withUnsafeBytes(of: encoded.littleEndian) { buf in
                return (buf[0], buf[1])
            }
        }
    }
}

extension ExtrinsicEra: ScaleCodable {
    public init(from decoder: ScaleDecoder) throws {
        let first: UInt8 = try decoder.decode()
        let val = first == 0
            ? Self(b1: first, b2: nil)
            : try Self(b1: first, b2: decoder.decode(UInt8.self))
        guard let val = val else {
            throw SDecodingError.dataCorrupted(
                SDecodingError.Context(
                    path: decoder.path,
                    description: "Invalid period and phase"
                )
            )
        }
        self = val
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        let data = serialize()
        try encoder.encode(data.0)
        if let second = data.1 {
            try encoder.encode(second)
        }
    }
}

extension ExtrinsicEra: RegistryScaleCodable {}

extension ExtrinsicEra: ValueConvertible {
    public init<C>(value: Value<C>) throws {
        let parseFields = { (fields: [String: Value<C>]) -> Self in
            guard fields.count == 2 else {
                throw ValueInitializableError<C>.wrongValuesCount(in: value.value,
                                                                  expected: 2,
                                                                  for: "ExtrinsicEra")
            }
            guard let period = fields["period"]?.u256 else {
                throw ValueInitializableError<C>.wrongValueType(got: value.value, for: "ExtrinsicEra")
            }
            if let phase = fields["phase"]?.u256 {
                return .mortal(period: UInt64(period), phase: UInt64(phase))
            } else if let current = fields["current"]?.u256 {
                return Self(period: UInt64(period), current: UInt64(current))
            } else {
                throw ValueInitializableError<C>.wrongValueType(got: value.value, for: "ExtrinsicEra")
            }
        }
        switch value.value {
        case .map(let fields):
            guard fields.count == 2 else {
                throw ValueInitializableError<C>.wrongValuesCount(in: value.value,
                                                                  expected: 2,
                                                                  for: "ExtrinsicEra")
            }
            self = try parseFields(fields)
        case .sequence(let values):
            guard values.count == 2 else {
                throw ValueInitializableError<C>.wrongValuesCount(in: value.value,
                                                                  expected: 2,
                                                                  for: "ExtrinsicEra")
            }
            guard let period = values[0].u256, let phase = values[1].u256 else {
                throw ValueInitializableError<C>.wrongValueType(got: value.value,
                                                                for: "ExtrinsicExtra")
            }
            self = .mortal(period: UInt64(period), phase: UInt64(phase))
        case .variant(let variant):
            if variant.name == "Immortal" {
                self = .immortal
                return
            }
            guard variant.name.starts(with: "Mortal") else {
                throw ValueInitializableError<C>.unknownVariant(name: variant.name,
                                                                in: value.value,
                                                                for: "ExtrinsicEra")
            }
            if variant.name == "Mortal" {
                guard let fields = variant.fields else {
                    throw ValueInitializableError<C>.wrongValueType(got: value.value, for: "ExtrinsicEra")
                }
                self = try parseFields(fields)
            } else {
                let vals = variant.values
                guard vals.count == 1 else {
                    throw ValueInitializableError<C>.wrongValuesCount(in: value.value,
                                                                      expected: 1,
                                                                      for: "ExtrinsicEra")
                }
                guard let second = vals.first?.u256 else {
                    throw ValueInitializableError<C>.wrongValueType(got: value.value,
                                                                    for: "ExtrinsicExtra")
                }
                let first = UInt8(variant.name.replacingOccurrences(of: "Mortal", with: ""), radix: 10)
                guard let first = first else {
                    throw ValueInitializableError<C>.unknownVariant(name: variant.name,
                                                                    in: value.value,
                                                                    for: "ExtrinsicEra")
                }
                guard let val = Self(b1: first, b2: UInt8(second)) else {
                    throw ValueInitializableError<C>.wrongValueType(got: value.value,
                                                                    for: "ExtrinsicExtra")
                }
                self = val
            }
        default: throw ValueInitializableError<C>.wrongValueType(got: value.value, for: "ExtrinsicEra")
        }
    }
    
    public func asValue() throws -> Value<Void> {
        switch self {
        case .immortal: return .variant(name: "Immortal", fields: [])
        case .mortal(period: let period, phase: let phase):
            return .variant(name: "Mortal",
                            fields: ["period": .u256(UInt256(period)), "phase": .u256(UInt256(phase))])
        }
    }
}

extension UInt64 {
    fileprivate var _nextPowerOfTwo: UInt64? {
        let i = Self.bitWidth - self.leadingZeroBitCount
        guard i < 64 else { return nil }
        return 1 << i
    }
}
