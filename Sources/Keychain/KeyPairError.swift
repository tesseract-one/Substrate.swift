//
//  KeyPairError.swift
//  
//
//  Created by Yehor Popovych on 13.05.2021.
//

import Foundation
import Substrate
import Bip39

public enum KeyPairError: Error {
    public enum SecretParsing: Error {
        case invalidFormat
        case invalidPath
        case invalidPhrase
        case invalidSeed
        case unknown(error: Error)
    }
    
    public enum PublicParsing: Error {
        case ss58(error: SS58.Error)
        case invalidFormat
        case invalidPath
        case unknown(error: Error)
    }
    
    public enum KeyDerive: Error {
        case publicDeriveHasHardPath
        case softDeriveIsNotSupported
        case badComponentSize
    }
    
    public enum BadInputData: Error {
        case seed
        case signature
        case message
        case publicKey
        case threshold
        case privateKey
    }
    
    public enum NativeLibrary: Error {
        case `internal`
        case badPrivateKey
    }
    
    case secretParsing(error: SecretParsing)
    case publicParsing(error: PublicParsing)
    case bip39(error: Mnemonic.Error)
    case derive(error: KeyDerive)
    case input(error: BadInputData)
    case native(error: NativeLibrary)
    case unknown(error: Error)
    
    public init(error: Error) {
        switch error {
        case let e as SecretParsing: self = .secretParsing(error: e)
        case let e as PublicParsing: self = .publicParsing(error: e)
        case let e as Mnemonic.Error: self = .bip39(error: e)
        case let e as KeyDerive: self = .derive(error: e)
        case let e as BadInputData: self = .input(error: e)
        case let e as NativeLibrary: self = .native(error: e)
        case let e as KeyPairError: self = e
        default: self = .unknown(error: error)
        }
    }
}
