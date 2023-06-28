//
//  Resources.swift
//  
//
//  Created by Yehor Popovych on 28/06/2023.
//

import Foundation

class Resources {
    private var meta14: Data? = nil
    private var meta15: Data? = nil
    
    func fileUrl(name: String) -> URL {
        #if Xcode
        let resUrl = Bundle.module.resourceURL!
        #else
        let resUrl = Bundle.module.bundleURL
        #endif
        return resUrl
            .appendingPathComponent("Resources")
            .appendingPathComponent(name)
    }
    func metadadav14() -> Data {
        guard let meta = meta14 else {
            meta14 = try! Data(contentsOf: fileUrl(name: "metadata-v14.bin"))
            return meta14!
        }
        return meta
    }
    
    func metadadav15() -> Data {
        guard let meta = meta15 else {
            meta15 = try! Data(contentsOf: fileUrl(name: "metadata-v15.bin"))
            return meta15!
        }
        return meta
    }
    
    static let inst = Resources()
}

#if !SWIFT_PACKAGE
extension Foundation.Bundle {
    static var module = Bundle(for: Resources.self)
}
#endif
