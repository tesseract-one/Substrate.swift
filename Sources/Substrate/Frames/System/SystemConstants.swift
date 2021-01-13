//
//  SystemConstants.swift
//  
//
//  Created by Yehor Popovych on 1/13/21.
//

import Foundation

/// The maximum number of blocks to allow in mortal eras.
public struct SytemBlockHashCountConstant<S: System>: Constant {
    public typealias Value = S.TBlockNumber
    public typealias Module = SystemModule<S>
    public static var NAME: String { "BlockHashCount" }
}

/// The maximum weight of a block.
public struct SytemMaximumBlockWeightConstant<S: System>: Constant {
    public typealias Value = Weight
    public typealias Module = SystemModule<S>
    public static var NAME: String { "MaximumBlockWeight" }
}

/// The weight of runtime database operations the runtime can invoke.
public struct SytemDbWeightConstant<S: System>: Constant {
    public typealias Value = RuntimeDbWeight
    public typealias Module = SystemModule<S>
    public static var NAME: String { "DbWeight" }
}

/// The base weight of executing a block, independent of the transactions in the block.
public struct SytemBlockExecutionWeightConstant<S: System>: Constant {
    public typealias Value = Weight
    public typealias Module = SystemModule<S>
    public static var NAME: String { "BlockExecutionWeight" }
}

/// The base weight of an Extrinsic in the block, independent of the of extrinsic being executed.
public struct SytemExtrinsicBaseWeightConstant<S: System>: Constant {
    public typealias Value = Weight
    public typealias Module = SystemModule<S>
    public static var NAME: String { "ExtrinsicBaseWeight" }
}

/// The maximum length of a block (in bytes).
public struct SytemMaximumBlockLengthConstant<S: System>: Constant {
    public typealias Value = UInt32
    public typealias Module = SystemModule<S>
    public static var NAME: String { "MaximumBlockLength" }
}
