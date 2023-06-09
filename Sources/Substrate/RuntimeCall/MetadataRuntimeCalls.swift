//
//  MetadataRuntimeCalls.swift
//  
//
//  Created by Yehor Popovych on 09/06/2023.
//

import Foundation

public protocol SomeMetadataVersionsRuntimeCall: StaticCodableRuntimeCall
    where TReturn == [UInt32]
{
    init()
}

public protocol SomeMetadataAtVersionRuntimeCall: StaticCodableRuntimeCall
    where TReturn == Optional<VersionedMetadata>
{
    init(version: UInt32)
}
