//
//  SubstrateFeeInfo.swift
//  
//
//  Created by Yehor Popovych on 22/08/2023.
//

import Foundation
import ScaleCodec

public struct DispatchInfo: ScaleCodec.Decodable, RuntimeDecodable, RuntimeDynamicDecodable {
    public let weightRefTime: UInt64
    public let weightProofSize: UInt64
    public let clazz: UInt8
    public let partialFee: UInt128
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
        weightRefTime = try decoder.decode(.compact)
        weightProofSize = try decoder.decode(.compact)
        clazz = try decoder.decode()
        partialFee = try decoder.decode()
    }
}

public struct FeeDetails: ScaleCodec.Decodable, RuntimeDecodable, RuntimeDynamicDecodable {
    public struct InclusionFee: ScaleCodec.Decodable {
        /// minimum amount a user pays for a transaction.
        public let baseFee: UInt128
        /// amount paid for the encoded length (in bytes) of the transaction.
        public let lenFee: UInt128
        ///
        /// - `targeted_fee_adjustment`: This is a multiplier that can tune the final fee based on the
        ///   congestion of the network.
        /// - `weight_fee`: This amount is computed based on the weight of the transaction. Weight
        /// accounts for the execution time of a transaction.
        ///
        /// adjusted_weight_fee = targeted_fee_adjustment * weight_fee
        public let adjustedWeightFee: UInt128
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
            baseFee = try decoder.decode()
            lenFee = try decoder.decode()
            adjustedWeightFee = try decoder.decode()
        }
    }
    /// The minimum fee for a transaction to be included in a block.
    public let inclusionFee: Optional<InclusionFee>
    /// tip
    public let tip: UInt128
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
        inclusionFee = try decoder.decode()
        tip = try decoder.decode()
    }
}
