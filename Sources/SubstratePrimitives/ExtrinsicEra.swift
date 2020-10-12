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
}

extension ExtrinsicEra: ScaleCodable {
    public init(from decoder: ScaleDecoder) throws {
        let first: UInt8 = try decoder.decode()
        if first == 0 {
            self = .immortal
        } else {
            let encoded = try UInt64(first) + UInt64(decoder.decode(UInt8.self)) << 8
            let period = 2 << (encoded % (1 << 4))
            let quantize_factor = max((period >> 12), 1)
            let phase = (encoded >> 4) * quantize_factor
            guard period >= 4 && phase < period else {
                throw SDecodingError.dataCorrupted(
                    SDecodingError.Context(
                        path: decoder.path,
                        description: "Invalid period and phase"
                    )
                )
            }
            self = .mortal(period: period, phase: phase)
        }
    }
    
    public func encode(in encoder: ScaleEncoder) throws {
        switch self {
        case .immortal: try encoder.encode(UInt8(0))
        case .mortal(period: let period, phase: let phase):
            let quantize_factor = max((period >> 12), 1)
            let encoded = UInt16(min(max(period.trailingZeroBitCount - 1, 1), 15))
                | UInt16((phase / quantize_factor) << 4)
            try encoder.encode(encoded)
        }
    }
}

extension ExtrinsicEra: ScaleRegistryCodable {}

extension UInt64 {
    fileprivate var _nextPowerOfTwo: UInt64? {
        let i = flsll(Int64(bitPattern: self))
        guard i < 64 else { return nil }
        return 1 << i
    }
}
