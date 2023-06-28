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
    
    func fileUrl(name: String, ext: String? = nil) -> URL {
        let path = Bundle.module.path(forResource: name, ofType: ext, inDirectory: "Resources")!
        return URL(fileURLWithPath: path)
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

#if COCOAPODS
extension Foundation.Bundle {
    static var module = Bundle(for: Resources.self)
}
#endif
