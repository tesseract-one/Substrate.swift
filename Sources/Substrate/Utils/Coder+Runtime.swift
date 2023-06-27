//
//  Coder+Runtime.swift
//  
//
//  Created by Yehor Popovych on 27/06/2023.
//

import Foundation

extension CodingUserInfoKey {
    public static let substrateRuntime = CodingUserInfoKey(rawValue: "SubstrateRuntimeKey")!
}

extension Encoder {
    public var runtime: any Runtime { userInfo[.substrateRuntime]! as! any Runtime }
}

extension Decoder {
    public var runtime: any Runtime { userInfo[.substrateRuntime]! as! any Runtime }
}
