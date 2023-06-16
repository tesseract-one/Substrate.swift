//
//  Lock.swift
//  
//
//  Created by Yehor Popovych on 30.12.2022.
//

import Foundation
#if os(Linux) || os(Windows)
import Glibc

public class Synced<T> {
    private var _value: T
    private var _mutex: pthread_mutex_t
    
    public var value: T { sync { $0 } }
    
    public init(value: T) {
        self._mutex = pthread_mutex_t()
        self._value = value
        if pthread_mutex_init(&_mutex, nil) != 0 {
            fatalError("Mutex creation failed!")
        }
    }
    
    public func sync<U>(_ op: (inout T) throws -> U) rethrows -> U {
        if pthread_mutex_lock(&_mutex) != 0 {
            fatalError("Mutex lock failed!")
        }
        defer {
            if pthread_mutex_unlock(&_mutex) != 0 {
                fatalError("Mutex unlock failed!")
            }
        }
        return try op(&_value)
    }
    
    deinit {
        if pthread_mutex_destroy(&_mutex) != 0 {
            fatalError("Mutex desctruction failed!")
        }
    }
}
#else
public class Synced<T> {
    private var _value: T
    private var _mutex: os_unfair_lock

    public init(value: T) {
        self._value = value
        self._mutex = .init()
    }
    
    public var value: T { sync { $0 } }

    public func sync<U>(_ op: (inout T) throws -> U) rethrows -> U {
        os_unfair_lock_lock(&_mutex)
        defer { os_unfair_lock_unlock(&_mutex) }
        return try op(&_value)
    }
}
#endif
