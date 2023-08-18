//
//  DynamicExtrinsicExtensions.swift
//  
//
//  Created by Yehor Popovych on 17/08/2023.
//

import Foundation
import Tuples

extension CheckSpecVersionExtension: DynamicExtrinsicExtension where P == AnySigningParams<C> {}

public typealias DynamicCheckSpecVersionExtension<C: Config> = CheckSpecVersionExtension<C, AnySigningParams<C>>

extension CheckTxVersionExtension: DynamicExtrinsicExtension where P == AnySigningParams<C> {}

public typealias DynamicCheckTxVersionExtension<C: Config> = CheckTxVersionExtension<C, AnySigningParams<C>>

extension CheckGenesisExtension: DynamicExtrinsicExtension where P == AnySigningParams<C> {}

public typealias DynamicCheckGenesisExtension<C: Config> = CheckGenesisExtension<C, AnySigningParams<C>>

extension CheckNonZeroSenderExtension: DynamicExtrinsicExtension where P == AnySigningParams<C> {}

public typealias DynamicCheckNonZeroSenderExtension<C: Config> = CheckNonZeroSenderExtension<C, AnySigningParams<C>>

extension CheckNonceExtension: DynamicExtrinsicExtension
    where P == AnySigningParams<C>, P.TPartial.TNonce: ValueRepresentable,
          P.TPartial.TAccountId: ValueRepresentable  {}

public typealias DynamicCheckNonceExtension<C: Config> = CheckNonceExtension<C, AnySigningParams<C>>

extension CheckMortalityExtension: DynamicExtrinsicExtension where P == AnySigningParams<C> {}

public typealias DynamicCheckMortalityExtension<C: Config> = CheckMortalityExtension<C, AnySigningParams<C>>

extension CheckWeightExtension: DynamicExtrinsicExtension where P == AnySigningParams<C> {}

public typealias DynamicCheckWeightExtension<C: Config> = CheckWeightExtension<C, AnySigningParams<C>>

extension ChargeTransactionPaymentExtension: DynamicExtrinsicExtension where P == AnySigningParams<C> {}

public extension ChargeTransactionPaymentExtension {
    static func tipType(runtime: any Runtime) -> RuntimeType.Info? {
        guard let ext = runtime.metadata.extrinsic.extensions.first(where: {
            $0.identifier == Self.identifier.rawValue
        }) else {
            return nil
        }
        return ext.type
    }
}

public typealias DynamicChargeTransactionPaymentExtension<C: Config> =
    ChargeTransactionPaymentExtension<C, AnySigningParams<C>>

extension PrevalidateAttestsExtension: DynamicExtrinsicExtension where P == AnySigningParams<C> {}

public typealias DynamicPrevalidateAttestsExtension<C: Config> =
    PrevalidateAttestsExtension<C, AnySigningParams<C>>

public typealias AllDynamicExtensions<C: Config> = Tuple9<
    DynamicCheckSpecVersionExtension<C>,
    DynamicCheckTxVersionExtension<C>,
    DynamicCheckGenesisExtension<C>,
    DynamicCheckNonZeroSenderExtension<C>,
    DynamicCheckNonceExtension<C>,
    DynamicCheckMortalityExtension<C>,
    DynamicCheckWeightExtension<C>,
    DynamicChargeTransactionPaymentExtension<C>,
    DynamicPrevalidateAttestsExtension<C>
>
