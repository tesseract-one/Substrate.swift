//
//  Values.swift
//  
//
//  Created by Yehor Popovych on 03/07/2023.
//

import Foundation
import ScaleCodec

extension Tuple0: ValueRepresentable, ValueArrayRepresentable {
    public func asValueArray() throws -> [Value<Void>] { [] }
}

extension Tuple1: ValueRepresentable, ValueArrayRepresentable
    where T1: ValueRepresentable
{
    public func asValueArray() throws -> [Value<Void>] {
        try [_0.asValue()]
    }
}

extension Tuple2: ValueRepresentable, ValueArrayRepresentable
    where T1: ValueRepresentable, T2: ValueRepresentable
{
    public func asValueArray() throws -> [Value<Void>] {
        try [_0.asValue(), _1.asValue()]
    }
}

extension Tuple3: ValueRepresentable, ValueArrayRepresentable
    where T1: ValueRepresentable, T2: ValueRepresentable, T3: ValueRepresentable
{
    public func asValueArray() throws -> [Value<Void>] {
        try [_0.asValue(), _1.asValue(), _2.asValue()]
    }
}

extension Tuple4: ValueRepresentable, ValueArrayRepresentable
    where T1: ValueRepresentable, T2: ValueRepresentable, T3: ValueRepresentable,
          T4: ValueRepresentable
{
    public func asValueArray() throws -> [Value<Void>] {
        try [_0.asValue(), _1.asValue(), _2.asValue(), _3.asValue()]
    }
}

extension Tuple5: ValueRepresentable, ValueArrayRepresentable
    where T1: ValueRepresentable, T2: ValueRepresentable, T3: ValueRepresentable,
          T4: ValueRepresentable, T5: ValueRepresentable
{
    public func asValueArray() throws -> [Value<Void>] {
        try [_0.asValue(), _1.asValue(), _2.asValue(), _3.asValue(), _4.asValue()]
    }
}

extension Tuple6: ValueRepresentable, ValueArrayRepresentable
    where T1: ValueRepresentable, T2: ValueRepresentable, T3: ValueRepresentable,
          T4: ValueRepresentable, T5: ValueRepresentable, T6: ValueRepresentable
{
    public func asValueArray() throws -> [Value<Void>] {
        try [_0.asValue(), _1.asValue(), _2.asValue(), _3.asValue(), _4.asValue(), _5.asValue()]
    }
}

extension Tuple7: ValueRepresentable, ValueArrayRepresentable
    where T1: ValueRepresentable, T2: ValueRepresentable, T3: ValueRepresentable,
          T4: ValueRepresentable, T5: ValueRepresentable, T6: ValueRepresentable,
          T7: ValueRepresentable
{
    public func asValueArray() throws -> [Value<Void>] {
        try [_0.asValue(), _1.asValue(), _2.asValue(), _3.asValue(), _4.asValue(), _5.asValue(),
             _6.asValue()]
    }
}

extension Tuple8: ValueRepresentable, ValueArrayRepresentable
    where T1: ValueRepresentable, T2: ValueRepresentable, T3: ValueRepresentable,
          T4: ValueRepresentable, T5: ValueRepresentable, T6: ValueRepresentable,
          T7: ValueRepresentable, T8: ValueRepresentable
{
    public func asValueArray() throws -> [Value<Void>] {
        try [_0.asValue(), _1.asValue(), _2.asValue(), _3.asValue(), _4.asValue(), _5.asValue(),
             _6.asValue(), _7.asValue()]
    }
}

extension Tuple9: ValueRepresentable, ValueArrayRepresentable
    where T1: ValueRepresentable, T2: ValueRepresentable, T3: ValueRepresentable,
          T4: ValueRepresentable, T5: ValueRepresentable, T6: ValueRepresentable,
          T7: ValueRepresentable, T8: ValueRepresentable, T9: ValueRepresentable
{
    public func asValueArray() throws -> [Value<Void>] {
        try [_0.asValue(), _1.asValue(), _2.asValue(), _3.asValue(), _4.asValue(), _5.asValue(),
             _6.asValue(), _7.asValue(), _8.asValue()]
    }
}

extension Tuple10: ValueRepresentable, ValueArrayRepresentable
    where T1: ValueRepresentable, T2: ValueRepresentable, T3: ValueRepresentable,
          T4: ValueRepresentable, T5: ValueRepresentable, T6: ValueRepresentable,
          T7: ValueRepresentable, T8: ValueRepresentable, T9: ValueRepresentable,
          T10: ValueRepresentable
{
    public func asValueArray() throws -> [Value<Void>] {
        try [_0.asValue(), _1.asValue(), _2.asValue(), _3.asValue(), _4.asValue(), _5.asValue(),
             _6.asValue(), _7.asValue(), _8.asValue(), _9.asValue()]
    }
}
