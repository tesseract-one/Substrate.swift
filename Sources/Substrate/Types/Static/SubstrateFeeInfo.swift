//
//  SubstrateFeeInfo.swift
//  
//
//  Created by Yehor Popovych on 22/08/2023.
//

import Foundation
import ScaleCodec

public struct DispatchInfo: ScaleCodec.Decodable, RuntimeDecodable,
                            RuntimeDynamicDecodable, RuntimeDynamicValidatableStaticComposite
{
    public struct Weight: ScaleCodec.Decodable, RuntimeDecodable,
                          RuntimeDynamicDecodable,
                          RuntimeDynamicValidatableStaticComposite
    {
        public let refTime: UInt64
        public let proofSize: UInt64
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
            refTime = try decoder.decode(.compact)
            proofSize = try decoder.decode(.compact)
        }
        
        public static var validatableFields: [RuntimeDynamicValidatable.Type] {
            [Compact<UInt64>.self, Compact<UInt64>.self]
        }
    }
    
    public enum DispatchClass: UInt8, CaseIterable, ScaleCodec.Codable, RuntimeDecodable,
                               RuntimeDynamicDecodable, RuntimeDynamicValidatableStaticVariant
    {
        case normal
        case operational
        case mandatory
    }
    
    public enum Pays: UInt8, CaseIterable, ScaleCodec.Codable, RuntimeDecodable,
                      RuntimeDynamicDecodable, RuntimeDynamicValidatableStaticVariant
    {
        case yes
        case no
    }
    
    public let weight: Weight
    public let clazz: DispatchClass
    public let paysFee: Pays
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
        weight = try decoder.decode()
        clazz = try decoder.decode()
        paysFee = try decoder.decode()
    }
    
    public static var validatableFields: [RuntimeDynamicValidatable.Type] {
        [Weight.self, DispatchClass.self, Pays.self]
    }
}


public struct RuntimeDispatchInfo<Bal: ConfigUnsignedInteger>: RuntimeDecodable,
                                                               RuntimeDynamicDecodable,
                                                               RuntimeDynamicValidatableStaticComposite
{
    public let weight: DispatchInfo.Weight
    public let clazz: DispatchInfo.DispatchClass
    public let partialFee: Bal
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: any Runtime) throws {
        weight = try decoder.decode()
        clazz = try decoder.decode()
        partialFee = try runtime.decode(from: &decoder)
    }
    
    public static var validatableFields: [RuntimeDynamicValidatable.Type] {
        [DispatchInfo.Weight.self, DispatchInfo.DispatchClass.self, Bal.self]
    }
}

public struct FeeDetails<Bal: ConfigUnsignedInteger>: RuntimeDecodable,
                                                      RuntimeDynamicDecodable,
                                                      RuntimeDynamicValidatableStaticComposite
{
    public struct InclusionFee: RuntimeDecodable, RuntimeDynamicValidatableStaticComposite {
        /// minimum amount a user pays for a transaction.
        public let baseFee: Bal
        /// amount paid for the encoded length (in bytes) of the transaction.
        public let lenFee: Bal
        ///
        /// - `targeted_fee_adjustment`: This is a multiplier that can tune the final fee based on the
        ///   congestion of the network.
        /// - `weight_fee`: This amount is computed based on the weight of the transaction. Weight
        /// accounts for the execution time of a transaction.
        ///
        /// adjusted_weight_fee = targeted_fee_adjustment * weight_fee
        public let adjustedWeightFee: Bal
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: any Runtime) throws {
            baseFee = try runtime.decode(from: &decoder)
            lenFee = try runtime.decode(from: &decoder)
            adjustedWeightFee = try runtime.decode(from: &decoder)
        }
        
        public static var validatableFields: [RuntimeDynamicValidatable.Type] {
            [Bal.self, Bal.self, Bal.self]
        }
    }
    
    /// The minimum fee for a transaction to be included in a block.
    public let inclusionFee: Optional<InclusionFee>
    /// tip
    public let tip: Bal
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: any Runtime) throws {
        inclusionFee = try runtime.decode(from: &decoder)
        tip = try runtime.decode(from: &decoder)
    }
    
    public static var validatableFields: [RuntimeDynamicValidatable.Type] {
        [Optional<InclusionFee>.self, Bal.self]
    }
}
