//
//  SignedExtension.swift
//  
//
//  Created by Yehor Popovych on 2/6/21.
//

import Foundation
import ScaleCodec

public protocol SignedExtension: ScaleDynamicCodable {
    /// Any additional data that will go into the signed payload. This may be created dynamically
    /// from the transaction using the `additionalSignedPayload` function.
    associatedtype AdditionalSignedPayload: ScaleDynamicCodable
    
    /// Construct any additional data that should be in the signed payload of the transaction. Can
    /// also perform any pre-signature-verification checks and return an error if needed.
    func additionalSignedPayload() throws -> AdditionalSignedPayload
    
    /// Returns the list of unique identifier for this signed extension.
    ///
    /// As a [`SignedExtension`] can be a tuple of [`SignedExtension`]s we need to return an `Array`
    /// that holds all the unique identifiers. Each individual `SignedExtension` must return
    /// *exactly* one identifier.
    ///
    /// This method provides a default implementation that returns `[Self.IDENTIFIER]`.
    var identifier: [String] { get }
    
    /// Unique identifier of this signed extension.
    ///
    /// This will be exposed in the metadata to identify the signed extension used
    /// in an extrinsic.
    static var IDENTIFIER: String { get }
}

extension SignedExtension {
    public var identifier: [String] { [Self.IDENTIFIER] }
}
