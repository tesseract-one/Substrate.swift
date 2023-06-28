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
        // Bundle.url(forResource:) should be used for both
        // but it crashes on Linux (CoreFoundation memory management bug)
        // so we have this workaround
        #if os(Linux) || os(Windows)
        return Bundle.module.bundleURL
            .appendingPathComponent("Resources")
            .appendingPathComponent(name)
        #else
        return Bundle.module.url(forResource: name,
                                 withExtension: nil,
                                 subdirectory: "Resources")!
        #endif
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
    // Load xctest bundle
    static var module = Bundle(for: Resources.self)
}
#endif
