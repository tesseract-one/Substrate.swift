//
//  Result.swift
//  
//
//  Created by Yehor Popovych on 21/08/2023.
//

import Foundation

public protocol ResultLike {
    associatedtype Success
    associatedtype Failure
    
    var isError: Bool { get }
    
    var value: Success? { get }
    var error: Failure? { get }
    
    func get() throws -> Success
}

public extension ResultLike where Failure: Error {
    var result: Result<Success, Failure> {
        isError ? .failure(error!) : .success(value!)
    }
}

extension Result: ResultLike {
    public var isError: Bool {
        switch self {
        case .failure(_): return true
        case .success(_): return false
        }
    }
    
    public var value: Success? {
        switch self {
        case .failure(_): return nil
        case .success(let v): return v
        }
    }
    
    public var error: Failure? {
        switch self {
        case .failure(let e): return e
        case .success(_): return nil
        }
    }
}

public extension Sequence where Element: ResultLike, Element.Failure: Error {
    func sequence() -> Result<[Element.Success], Element.Failure> {
        reduce(.success([])) { (p, q) in
            p.flatMap { x in q.result.map { x + [$0] } }
        }
    }
}

public extension Collection {
    func resultMap<T, E: Error>(_ mapper: (Element) -> Result<T, E>) -> Result<Array<T>, E> {
        var new: [T] = []
        new.reserveCapacity(count)
        for val in self {
            switch mapper(val) {
            case .failure(let e): return .failure(e)
            case .success(let v): new.append(v)
            }
        }
        return .success(new)
    }
}
