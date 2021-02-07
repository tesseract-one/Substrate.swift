//
// Generated '2021-02-07 00:17:29 +0000' with 'generate_se_tuples.swift'
//
import Foundation
import ScaleCodec

extension STuple2: SignedExtension
    where
        T1: SignedExtension, T2: SignedExtension
{
    public typealias AdditionalSignedPayload = STuple2<
        T1.AdditionalSignedPayload, T2.AdditionalSignedPayload
    >

    public var identifier: [String] {
        var identifiers = Array<String>()
        identifiers.append(contentsOf: _0.identifier); identifiers.append(contentsOf: _1.identifier)
        return identifiers
    }

    public func additionalSignedPayload() throws -> AdditionalSignedPayload {
        return try AdditionalSignedPayload(
            _0.additionalSignedPayload(), _1.additionalSignedPayload()
        )
    }

    public static var IDENTIFIER: String { "" }
}

extension STuple3: SignedExtension
    where
        T1: SignedExtension, T2: SignedExtension, T3: SignedExtension
{
    public typealias AdditionalSignedPayload = STuple3<
        T1.AdditionalSignedPayload, T2.AdditionalSignedPayload, T3.AdditionalSignedPayload
    >

    public var identifier: [String] {
        var identifiers = Array<String>()
        identifiers.append(contentsOf: _0.identifier); identifiers.append(contentsOf: _1.identifier)
        identifiers.append(contentsOf: _2.identifier)
        return identifiers
    }

    public func additionalSignedPayload() throws -> AdditionalSignedPayload {
        return try AdditionalSignedPayload(
            _0.additionalSignedPayload(), _1.additionalSignedPayload(), _2.additionalSignedPayload()
        )
    }

    public static var IDENTIFIER: String { "" }
}

extension STuple4: SignedExtension
    where
        T1: SignedExtension, T2: SignedExtension, T3: SignedExtension, T4: SignedExtension
{
    public typealias AdditionalSignedPayload = STuple4<
        T1.AdditionalSignedPayload, T2.AdditionalSignedPayload, T3.AdditionalSignedPayload,
        T4.AdditionalSignedPayload
    >

    public var identifier: [String] {
        var identifiers = Array<String>()
        identifiers.append(contentsOf: _0.identifier); identifiers.append(contentsOf: _1.identifier)
        identifiers.append(contentsOf: _2.identifier); identifiers.append(contentsOf: _3.identifier)
        return identifiers
    }

    public func additionalSignedPayload() throws -> AdditionalSignedPayload {
        return try AdditionalSignedPayload(
            _0.additionalSignedPayload(), _1.additionalSignedPayload(), _2.additionalSignedPayload(),
            _3.additionalSignedPayload()
        )
    }

    public static var IDENTIFIER: String { "" }
}

extension STuple5: SignedExtension
    where
        T1: SignedExtension, T2: SignedExtension, T3: SignedExtension, T4: SignedExtension,
        T5: SignedExtension
{
    public typealias AdditionalSignedPayload = STuple5<
        T1.AdditionalSignedPayload, T2.AdditionalSignedPayload, T3.AdditionalSignedPayload,
        T4.AdditionalSignedPayload, T5.AdditionalSignedPayload
    >

    public var identifier: [String] {
        var identifiers = Array<String>()
        identifiers.append(contentsOf: _0.identifier); identifiers.append(contentsOf: _1.identifier)
        identifiers.append(contentsOf: _2.identifier); identifiers.append(contentsOf: _3.identifier)
        identifiers.append(contentsOf: _4.identifier)
        return identifiers
    }

    public func additionalSignedPayload() throws -> AdditionalSignedPayload {
        return try AdditionalSignedPayload(
            _0.additionalSignedPayload(), _1.additionalSignedPayload(), _2.additionalSignedPayload(),
            _3.additionalSignedPayload(), _4.additionalSignedPayload()
        )
    }

    public static var IDENTIFIER: String { "" }
}

extension STuple6: SignedExtension
    where
        T1: SignedExtension, T2: SignedExtension, T3: SignedExtension, T4: SignedExtension,
        T5: SignedExtension, T6: SignedExtension
{
    public typealias AdditionalSignedPayload = STuple6<
        T1.AdditionalSignedPayload, T2.AdditionalSignedPayload, T3.AdditionalSignedPayload,
        T4.AdditionalSignedPayload, T5.AdditionalSignedPayload, T6.AdditionalSignedPayload
    >

    public var identifier: [String] {
        var identifiers = Array<String>()
        identifiers.append(contentsOf: _0.identifier); identifiers.append(contentsOf: _1.identifier)
        identifiers.append(contentsOf: _2.identifier); identifiers.append(contentsOf: _3.identifier)
        identifiers.append(contentsOf: _4.identifier); identifiers.append(contentsOf: _5.identifier)
        return identifiers
    }

    public func additionalSignedPayload() throws -> AdditionalSignedPayload {
        return try AdditionalSignedPayload(
            _0.additionalSignedPayload(), _1.additionalSignedPayload(), _2.additionalSignedPayload(),
            _3.additionalSignedPayload(), _4.additionalSignedPayload(), _5.additionalSignedPayload()
        )
    }

    public static var IDENTIFIER: String { "" }
}

extension STuple7: SignedExtension
    where
        T1: SignedExtension, T2: SignedExtension, T3: SignedExtension, T4: SignedExtension,
        T5: SignedExtension, T6: SignedExtension, T7: SignedExtension
{
    public typealias AdditionalSignedPayload = STuple7<
        T1.AdditionalSignedPayload, T2.AdditionalSignedPayload, T3.AdditionalSignedPayload,
        T4.AdditionalSignedPayload, T5.AdditionalSignedPayload, T6.AdditionalSignedPayload,
        T7.AdditionalSignedPayload
    >

    public var identifier: [String] {
        var identifiers = Array<String>()
        identifiers.append(contentsOf: _0.identifier); identifiers.append(contentsOf: _1.identifier)
        identifiers.append(contentsOf: _2.identifier); identifiers.append(contentsOf: _3.identifier)
        identifiers.append(contentsOf: _4.identifier); identifiers.append(contentsOf: _5.identifier)
        identifiers.append(contentsOf: _6.identifier)
        return identifiers
    }

    public func additionalSignedPayload() throws -> AdditionalSignedPayload {
        return try AdditionalSignedPayload(
            _0.additionalSignedPayload(), _1.additionalSignedPayload(), _2.additionalSignedPayload(),
            _3.additionalSignedPayload(), _4.additionalSignedPayload(), _5.additionalSignedPayload(),
            _6.additionalSignedPayload()
        )
    }

    public static var IDENTIFIER: String { "" }
}

extension STuple8: SignedExtension
    where
        T1: SignedExtension, T2: SignedExtension, T3: SignedExtension, T4: SignedExtension,
        T5: SignedExtension, T6: SignedExtension, T7: SignedExtension, T8: SignedExtension
{
    public typealias AdditionalSignedPayload = STuple8<
        T1.AdditionalSignedPayload, T2.AdditionalSignedPayload, T3.AdditionalSignedPayload,
        T4.AdditionalSignedPayload, T5.AdditionalSignedPayload, T6.AdditionalSignedPayload,
        T7.AdditionalSignedPayload, T8.AdditionalSignedPayload
    >

    public var identifier: [String] {
        var identifiers = Array<String>()
        identifiers.append(contentsOf: _0.identifier); identifiers.append(contentsOf: _1.identifier)
        identifiers.append(contentsOf: _2.identifier); identifiers.append(contentsOf: _3.identifier)
        identifiers.append(contentsOf: _4.identifier); identifiers.append(contentsOf: _5.identifier)
        identifiers.append(contentsOf: _6.identifier); identifiers.append(contentsOf: _7.identifier)
        return identifiers
    }

    public func additionalSignedPayload() throws -> AdditionalSignedPayload {
        return try AdditionalSignedPayload(
            _0.additionalSignedPayload(), _1.additionalSignedPayload(), _2.additionalSignedPayload(),
            _3.additionalSignedPayload(), _4.additionalSignedPayload(), _5.additionalSignedPayload(),
            _6.additionalSignedPayload(), _7.additionalSignedPayload()
        )
    }

    public static var IDENTIFIER: String { "" }
}

extension STuple9: SignedExtension
    where
        T1: SignedExtension, T2: SignedExtension, T3: SignedExtension, T4: SignedExtension,
        T5: SignedExtension, T6: SignedExtension, T7: SignedExtension, T8: SignedExtension,
        T9: SignedExtension
{
    public typealias AdditionalSignedPayload = STuple9<
        T1.AdditionalSignedPayload, T2.AdditionalSignedPayload, T3.AdditionalSignedPayload,
        T4.AdditionalSignedPayload, T5.AdditionalSignedPayload, T6.AdditionalSignedPayload,
        T7.AdditionalSignedPayload, T8.AdditionalSignedPayload, T9.AdditionalSignedPayload
    >

    public var identifier: [String] {
        var identifiers = Array<String>()
        identifiers.append(contentsOf: _0.identifier); identifiers.append(contentsOf: _1.identifier)
        identifiers.append(contentsOf: _2.identifier); identifiers.append(contentsOf: _3.identifier)
        identifiers.append(contentsOf: _4.identifier); identifiers.append(contentsOf: _5.identifier)
        identifiers.append(contentsOf: _6.identifier); identifiers.append(contentsOf: _7.identifier)
        identifiers.append(contentsOf: _8.identifier)
        return identifiers
    }

    public func additionalSignedPayload() throws -> AdditionalSignedPayload {
        return try AdditionalSignedPayload(
            _0.additionalSignedPayload(), _1.additionalSignedPayload(), _2.additionalSignedPayload(),
            _3.additionalSignedPayload(), _4.additionalSignedPayload(), _5.additionalSignedPayload(),
            _6.additionalSignedPayload(), _7.additionalSignedPayload(), _8.additionalSignedPayload()
        )
    }

    public static var IDENTIFIER: String { "" }
}

extension STuple10: SignedExtension
    where
        T1: SignedExtension, T2: SignedExtension, T3: SignedExtension, T4: SignedExtension,
        T5: SignedExtension, T6: SignedExtension, T7: SignedExtension, T8: SignedExtension,
        T9: SignedExtension, T10: SignedExtension
{
    public typealias AdditionalSignedPayload = STuple10<
        T1.AdditionalSignedPayload, T2.AdditionalSignedPayload, T3.AdditionalSignedPayload,
        T4.AdditionalSignedPayload, T5.AdditionalSignedPayload, T6.AdditionalSignedPayload,
        T7.AdditionalSignedPayload, T8.AdditionalSignedPayload, T9.AdditionalSignedPayload,
        T10.AdditionalSignedPayload
    >

    public var identifier: [String] {
        var identifiers = Array<String>()
        identifiers.append(contentsOf: _0.identifier); identifiers.append(contentsOf: _1.identifier)
        identifiers.append(contentsOf: _2.identifier); identifiers.append(contentsOf: _3.identifier)
        identifiers.append(contentsOf: _4.identifier); identifiers.append(contentsOf: _5.identifier)
        identifiers.append(contentsOf: _6.identifier); identifiers.append(contentsOf: _7.identifier)
        identifiers.append(contentsOf: _8.identifier); identifiers.append(contentsOf: _9.identifier)
        return identifiers
    }

    public func additionalSignedPayload() throws -> AdditionalSignedPayload {
        return try AdditionalSignedPayload(
            _0.additionalSignedPayload(), _1.additionalSignedPayload(), _2.additionalSignedPayload(),
            _3.additionalSignedPayload(), _4.additionalSignedPayload(), _5.additionalSignedPayload(),
            _6.additionalSignedPayload(), _7.additionalSignedPayload(), _8.additionalSignedPayload(),
            _9.additionalSignedPayload()
        )
    }

    public static var IDENTIFIER: String { "" }
}
