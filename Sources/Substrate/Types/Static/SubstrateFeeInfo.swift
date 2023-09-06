//
//  SubstrateFeeInfo.swift
//  
//
//  Created by Yehor Popovych on 22/08/2023.
//

import Foundation
import ScaleCodec

public struct DispatchInfo: ScaleCodec.Decodable, RuntimeDecodable,
                            RuntimeDynamicDecodable, IdentifiableType
{
    public struct Weight: ScaleCodec.Decodable, RuntimeDecodable,
                          RuntimeDynamicDecodable, IdentifiableType
    {
        public let refTime: UInt64
        public let proofSize: UInt64
        
        public init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
            refTime = try decoder.decode(.compact)
            proofSize = try decoder.decode(.compact)
        }
        
        @inlinable
        public static var definition: TypeDefinition {
            .composite(fields: [.v(Compact<UInt64>.definition),
                                .v(Compact<UInt64>.definition)])
        }
    }
    
    public enum DispatchClass: UInt8, CaseIterable, ScaleCodec.Codable, RuntimeDecodable,
                               RuntimeDynamicDecodable, IdentifiableType
    {
        case normal
        case operational
        case mandatory
    }
    
    public enum Pays: UInt8, CaseIterable, ScaleCodec.Codable, RuntimeDecodable,
                      RuntimeDynamicDecodable, IdentifiableType
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
    
    @inlinable
    public static var definition: TypeDefinition {
        .composite(fields: [.v(Weight.definition),
                            .v(DispatchClass.definition),
                            .v(Pays.definition)])
    }
}


public struct RuntimeDispatchInfo<Bal: ConfigUnsignedInteger>: RuntimeDecodable,
                                                               RuntimeDynamicDecodable,
                                                               IdentifiableType
{
    public let weight: DispatchInfo.Weight
    public let clazz: DispatchInfo.DispatchClass
    public let partialFee: Bal
    
    public init<D: ScaleCodec.Decoder>(from decoder: inout D, runtime: any Runtime) throws {
        weight = try decoder.decode()
        clazz = try decoder.decode()
        partialFee = try runtime.decode(from: &decoder)
    }
    
    @inlinable
    public static var definition: TypeDefinition {
        .composite(fields: [.v(DispatchInfo.Weight.definition),
                            .v(DispatchInfo.DispatchClass.definition),
                            .v(Bal.definition)])
    }
}

public struct FeeDetails<Bal>: RuntimeDecodable, RuntimeDynamicDecodable, IdentifiableType
    where Bal: ConfigUnsignedInteger
{
    public struct InclusionFee: RuntimeDecodable, IdentifiableType {
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
        
        @inlinable
        public static var definition: TypeDefinition {
            .composite(fields: [.v(Bal.definition),
                                .v(Bal.definition),
                                .v(Bal.definition)])
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
    
    @inlinable
    public static var definition: TypeDefinition {
        .composite(fields: [.v(Optional<InclusionFee>.definition),
                            .v(Bal.definition)])
    }
}
