//
// Generated '2021-02-09 01:59:38 +0000' with 'generate_dc_tuples.swift'
//
import Foundation
import ScaleCodec

extension STuple2: DynamicTypeId {}

extension STuple2: ScaleDynamicEncodable
    where
        T1: ScaleDynamicEncodable, T2: ScaleDynamicEncodable
{
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try _0.encode(in: encoder, registry: registry); try _1.encode(in: encoder, registry: registry)
    }
}

extension STuple2: ScaleDynamicEncodableCollectionConvertible
    where
        T1: ScaleDynamicEncodable, T2: ScaleDynamicEncodable
{
    public var encodableCollection: DEncodableCollection {
        DEncodableCollection([_0, _1])
    }
}

extension STuple2: ScaleDynamicDecodable
    where
        T1: ScaleDynamicDecodable, T2: ScaleDynamicDecodable
{
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        try self.init(
            T1(from: decoder, registry: registry), T2(from: decoder, registry: registry)
        )
    }
}

extension STuple3: DynamicTypeId {}

extension STuple3: ScaleDynamicEncodable
    where
        T1: ScaleDynamicEncodable, T2: ScaleDynamicEncodable, T3: ScaleDynamicEncodable
{
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try _0.encode(in: encoder, registry: registry); try _1.encode(in: encoder, registry: registry)
        try _2.encode(in: encoder, registry: registry)
    }
}

extension STuple3: ScaleDynamicEncodableCollectionConvertible
    where
        T1: ScaleDynamicEncodable, T2: ScaleDynamicEncodable, T3: ScaleDynamicEncodable
{
    public var encodableCollection: DEncodableCollection {
        DEncodableCollection([_0, _1, _2])
    }
}

extension STuple3: ScaleDynamicDecodable
    where
        T1: ScaleDynamicDecodable, T2: ScaleDynamicDecodable, T3: ScaleDynamicDecodable
{
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        try self.init(
            T1(from: decoder, registry: registry), T2(from: decoder, registry: registry), T3(from: decoder, registry: registry)
        )
    }
}

extension STuple4: DynamicTypeId {}

extension STuple4: ScaleDynamicEncodable
    where
        T1: ScaleDynamicEncodable, T2: ScaleDynamicEncodable, T3: ScaleDynamicEncodable, T4: ScaleDynamicEncodable
{
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try _0.encode(in: encoder, registry: registry); try _1.encode(in: encoder, registry: registry)
        try _2.encode(in: encoder, registry: registry); try _3.encode(in: encoder, registry: registry)
    }
}

extension STuple4: ScaleDynamicEncodableCollectionConvertible
    where
        T1: ScaleDynamicEncodable, T2: ScaleDynamicEncodable, T3: ScaleDynamicEncodable, T4: ScaleDynamicEncodable
{
    public var encodableCollection: DEncodableCollection {
        DEncodableCollection([_0, _1, _2, _3])
    }
}

extension STuple4: ScaleDynamicDecodable
    where
        T1: ScaleDynamicDecodable, T2: ScaleDynamicDecodable, T3: ScaleDynamicDecodable, T4: ScaleDynamicDecodable
{
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        try self.init(
            T1(from: decoder, registry: registry), T2(from: decoder, registry: registry), T3(from: decoder, registry: registry),
            T4(from: decoder, registry: registry)
        )
    }
}

extension STuple5: DynamicTypeId {}

extension STuple5: ScaleDynamicEncodable
    where
        T1: ScaleDynamicEncodable, T2: ScaleDynamicEncodable, T3: ScaleDynamicEncodable, T4: ScaleDynamicEncodable,
        T5: ScaleDynamicEncodable
{
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try _0.encode(in: encoder, registry: registry); try _1.encode(in: encoder, registry: registry)
        try _2.encode(in: encoder, registry: registry); try _3.encode(in: encoder, registry: registry)
        try _4.encode(in: encoder, registry: registry)
    }
}

extension STuple5: ScaleDynamicEncodableCollectionConvertible
    where
        T1: ScaleDynamicEncodable, T2: ScaleDynamicEncodable, T3: ScaleDynamicEncodable, T4: ScaleDynamicEncodable,
        T5: ScaleDynamicEncodable
{
    public var encodableCollection: DEncodableCollection {
        DEncodableCollection([_0, _1, _2, _3, _4])
    }
}

extension STuple5: ScaleDynamicDecodable
    where
        T1: ScaleDynamicDecodable, T2: ScaleDynamicDecodable, T3: ScaleDynamicDecodable, T4: ScaleDynamicDecodable,
        T5: ScaleDynamicDecodable
{
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        try self.init(
            T1(from: decoder, registry: registry), T2(from: decoder, registry: registry), T3(from: decoder, registry: registry),
            T4(from: decoder, registry: registry), T5(from: decoder, registry: registry)
        )
    }
}

extension STuple6: DynamicTypeId {}

extension STuple6: ScaleDynamicEncodable
    where
        T1: ScaleDynamicEncodable, T2: ScaleDynamicEncodable, T3: ScaleDynamicEncodable, T4: ScaleDynamicEncodable,
        T5: ScaleDynamicEncodable, T6: ScaleDynamicEncodable
{
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try _0.encode(in: encoder, registry: registry); try _1.encode(in: encoder, registry: registry)
        try _2.encode(in: encoder, registry: registry); try _3.encode(in: encoder, registry: registry)
        try _4.encode(in: encoder, registry: registry); try _5.encode(in: encoder, registry: registry)
    }
}

extension STuple6: ScaleDynamicEncodableCollectionConvertible
    where
        T1: ScaleDynamicEncodable, T2: ScaleDynamicEncodable, T3: ScaleDynamicEncodable, T4: ScaleDynamicEncodable,
        T5: ScaleDynamicEncodable, T6: ScaleDynamicEncodable
{
    public var encodableCollection: DEncodableCollection {
        DEncodableCollection([_0, _1, _2, _3, _4, _5])
    }
}

extension STuple6: ScaleDynamicDecodable
    where
        T1: ScaleDynamicDecodable, T2: ScaleDynamicDecodable, T3: ScaleDynamicDecodable, T4: ScaleDynamicDecodable,
        T5: ScaleDynamicDecodable, T6: ScaleDynamicDecodable
{
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        try self.init(
            T1(from: decoder, registry: registry), T2(from: decoder, registry: registry), T3(from: decoder, registry: registry),
            T4(from: decoder, registry: registry), T5(from: decoder, registry: registry), T6(from: decoder, registry: registry)
        )
    }
}

extension STuple7: DynamicTypeId {}

extension STuple7: ScaleDynamicEncodable
    where
        T1: ScaleDynamicEncodable, T2: ScaleDynamicEncodable, T3: ScaleDynamicEncodable, T4: ScaleDynamicEncodable,
        T5: ScaleDynamicEncodable, T6: ScaleDynamicEncodable, T7: ScaleDynamicEncodable
{
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try _0.encode(in: encoder, registry: registry); try _1.encode(in: encoder, registry: registry)
        try _2.encode(in: encoder, registry: registry); try _3.encode(in: encoder, registry: registry)
        try _4.encode(in: encoder, registry: registry); try _5.encode(in: encoder, registry: registry)
        try _6.encode(in: encoder, registry: registry)
    }
}

extension STuple7: ScaleDynamicEncodableCollectionConvertible
    where
        T1: ScaleDynamicEncodable, T2: ScaleDynamicEncodable, T3: ScaleDynamicEncodable, T4: ScaleDynamicEncodable,
        T5: ScaleDynamicEncodable, T6: ScaleDynamicEncodable, T7: ScaleDynamicEncodable
{
    public var encodableCollection: DEncodableCollection {
        DEncodableCollection([_0, _1, _2, _3, _4, _5, _6])
    }
}

extension STuple7: ScaleDynamicDecodable
    where
        T1: ScaleDynamicDecodable, T2: ScaleDynamicDecodable, T3: ScaleDynamicDecodable, T4: ScaleDynamicDecodable,
        T5: ScaleDynamicDecodable, T6: ScaleDynamicDecodable, T7: ScaleDynamicDecodable
{
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        try self.init(
            T1(from: decoder, registry: registry), T2(from: decoder, registry: registry), T3(from: decoder, registry: registry),
            T4(from: decoder, registry: registry), T5(from: decoder, registry: registry), T6(from: decoder, registry: registry),
            T7(from: decoder, registry: registry)
        )
    }
}

extension STuple8: DynamicTypeId {}

extension STuple8: ScaleDynamicEncodable
    where
        T1: ScaleDynamicEncodable, T2: ScaleDynamicEncodable, T3: ScaleDynamicEncodable, T4: ScaleDynamicEncodable,
        T5: ScaleDynamicEncodable, T6: ScaleDynamicEncodable, T7: ScaleDynamicEncodable, T8: ScaleDynamicEncodable
{
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try _0.encode(in: encoder, registry: registry); try _1.encode(in: encoder, registry: registry)
        try _2.encode(in: encoder, registry: registry); try _3.encode(in: encoder, registry: registry)
        try _4.encode(in: encoder, registry: registry); try _5.encode(in: encoder, registry: registry)
        try _6.encode(in: encoder, registry: registry); try _7.encode(in: encoder, registry: registry)
    }
}

extension STuple8: ScaleDynamicEncodableCollectionConvertible
    where
        T1: ScaleDynamicEncodable, T2: ScaleDynamicEncodable, T3: ScaleDynamicEncodable, T4: ScaleDynamicEncodable,
        T5: ScaleDynamicEncodable, T6: ScaleDynamicEncodable, T7: ScaleDynamicEncodable, T8: ScaleDynamicEncodable
{
    public var encodableCollection: DEncodableCollection {
        DEncodableCollection([_0, _1, _2, _3, _4, _5, _6, _7])
    }
}

extension STuple8: ScaleDynamicDecodable
    where
        T1: ScaleDynamicDecodable, T2: ScaleDynamicDecodable, T3: ScaleDynamicDecodable, T4: ScaleDynamicDecodable,
        T5: ScaleDynamicDecodable, T6: ScaleDynamicDecodable, T7: ScaleDynamicDecodable, T8: ScaleDynamicDecodable
{
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        try self.init(
            T1(from: decoder, registry: registry), T2(from: decoder, registry: registry), T3(from: decoder, registry: registry),
            T4(from: decoder, registry: registry), T5(from: decoder, registry: registry), T6(from: decoder, registry: registry),
            T7(from: decoder, registry: registry), T8(from: decoder, registry: registry)
        )
    }
}

extension STuple9: DynamicTypeId {}

extension STuple9: ScaleDynamicEncodable
    where
        T1: ScaleDynamicEncodable, T2: ScaleDynamicEncodable, T3: ScaleDynamicEncodable, T4: ScaleDynamicEncodable,
        T5: ScaleDynamicEncodable, T6: ScaleDynamicEncodable, T7: ScaleDynamicEncodable, T8: ScaleDynamicEncodable,
        T9: ScaleDynamicEncodable
{
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try _0.encode(in: encoder, registry: registry); try _1.encode(in: encoder, registry: registry)
        try _2.encode(in: encoder, registry: registry); try _3.encode(in: encoder, registry: registry)
        try _4.encode(in: encoder, registry: registry); try _5.encode(in: encoder, registry: registry)
        try _6.encode(in: encoder, registry: registry); try _7.encode(in: encoder, registry: registry)
        try _8.encode(in: encoder, registry: registry)
    }
}

extension STuple9: ScaleDynamicEncodableCollectionConvertible
    where
        T1: ScaleDynamicEncodable, T2: ScaleDynamicEncodable, T3: ScaleDynamicEncodable, T4: ScaleDynamicEncodable,
        T5: ScaleDynamicEncodable, T6: ScaleDynamicEncodable, T7: ScaleDynamicEncodable, T8: ScaleDynamicEncodable,
        T9: ScaleDynamicEncodable
{
    public var encodableCollection: DEncodableCollection {
        DEncodableCollection([_0, _1, _2, _3, _4, _5, _6, _7, _8])
    }
}

extension STuple9: ScaleDynamicDecodable
    where
        T1: ScaleDynamicDecodable, T2: ScaleDynamicDecodable, T3: ScaleDynamicDecodable, T4: ScaleDynamicDecodable,
        T5: ScaleDynamicDecodable, T6: ScaleDynamicDecodable, T7: ScaleDynamicDecodable, T8: ScaleDynamicDecodable,
        T9: ScaleDynamicDecodable
{
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        try self.init(
            T1(from: decoder, registry: registry), T2(from: decoder, registry: registry), T3(from: decoder, registry: registry),
            T4(from: decoder, registry: registry), T5(from: decoder, registry: registry), T6(from: decoder, registry: registry),
            T7(from: decoder, registry: registry), T8(from: decoder, registry: registry), T9(from: decoder, registry: registry)
        )
    }
}

extension STuple10: DynamicTypeId {}

extension STuple10: ScaleDynamicEncodable
    where
        T1: ScaleDynamicEncodable, T2: ScaleDynamicEncodable, T3: ScaleDynamicEncodable, T4: ScaleDynamicEncodable,
        T5: ScaleDynamicEncodable, T6: ScaleDynamicEncodable, T7: ScaleDynamicEncodable, T8: ScaleDynamicEncodable,
        T9: ScaleDynamicEncodable, T10: ScaleDynamicEncodable
{
    public func encode(in encoder: ScaleEncoder, registry: TypeRegistryProtocol) throws {
        try _0.encode(in: encoder, registry: registry); try _1.encode(in: encoder, registry: registry)
        try _2.encode(in: encoder, registry: registry); try _3.encode(in: encoder, registry: registry)
        try _4.encode(in: encoder, registry: registry); try _5.encode(in: encoder, registry: registry)
        try _6.encode(in: encoder, registry: registry); try _7.encode(in: encoder, registry: registry)
        try _8.encode(in: encoder, registry: registry); try _9.encode(in: encoder, registry: registry)
    }
}

extension STuple10: ScaleDynamicEncodableCollectionConvertible
    where
        T1: ScaleDynamicEncodable, T2: ScaleDynamicEncodable, T3: ScaleDynamicEncodable, T4: ScaleDynamicEncodable,
        T5: ScaleDynamicEncodable, T6: ScaleDynamicEncodable, T7: ScaleDynamicEncodable, T8: ScaleDynamicEncodable,
        T9: ScaleDynamicEncodable, T10: ScaleDynamicEncodable
{
    public var encodableCollection: DEncodableCollection {
        DEncodableCollection([_0, _1, _2, _3, _4, _5, _6, _7, _8, _9])
    }
}

extension STuple10: ScaleDynamicDecodable
    where
        T1: ScaleDynamicDecodable, T2: ScaleDynamicDecodable, T3: ScaleDynamicDecodable, T4: ScaleDynamicDecodable,
        T5: ScaleDynamicDecodable, T6: ScaleDynamicDecodable, T7: ScaleDynamicDecodable, T8: ScaleDynamicDecodable,
        T9: ScaleDynamicDecodable, T10: ScaleDynamicDecodable
{
    public init(from decoder: ScaleDecoder, registry: TypeRegistryProtocol) throws {
        try self.init(
            T1(from: decoder, registry: registry), T2(from: decoder, registry: registry), T3(from: decoder, registry: registry),
            T4(from: decoder, registry: registry), T5(from: decoder, registry: registry), T6(from: decoder, registry: registry),
            T7(from: decoder, registry: registry), T8(from: decoder, registry: registry), T9(from: decoder, registry: registry),
            T10(from: decoder, registry: registry)
        )
    }
}
