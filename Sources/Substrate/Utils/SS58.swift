//
//  Ss58Codec.swift
//  
//
//  Created by Yehor Popovych on 04.05.2021.
//

import Foundation

public struct SS58 {
    public struct AddressFormat: RawRepresentable, Hashable, Codable {
        public typealias RawValue = UInt16
        
        public let id: UInt16
        public var rawValue: RawValue { id }
        
        public init?(rawValue: Self.RawValue) {
            guard rawValue != Self.reserved46.rawValue && rawValue != Self.reserved47.rawValue else {
                return nil
            }
            self.init(id: rawValue)
        }
        
        fileprivate init(id: UInt16) {
            self.id = id
        }
        
        /// Polkadot Relay-chain, standard account (*25519).
        public static let polkadot = Self(id: 0)
        /// Bare 32-bit Schnorr/Ristretto 25519 (S/R 25519) key.
        public static let bareSr25519 = Self(id: 1)
        /// Kusama Relay-chain, standard account (*25519).
        public static let kusama = Self(id: 2)
        /// Bare 32-bit Edwards Ed25519 key.
        public static let bareEd25519 = Self(id: 3)
        /// Katal Chain, standard account (*25519).
        public static let katalChain = Self(id: 4)
        /// Plasm Network, standard account (*25519).
        public static let plasm = Self(id: 5)
        /// Bifrost mainnet, direct checksum, standard account (*25519).
        public static let bitfrost = Self(id: 6)
        /// Edgeware mainnet, standard account (*25519).
        public static let edgeware = Self(id: 7)
        /// Acala Karura canary network, standard account (*25519).
        public static let karura = Self(id: 8)
        /// Laminar Reynolds canary network, standard account (*25519).
        public static let reynolds = Self(id: 9)
        /// Acala mainnet, standard account (*25519).
        public static let acala = Self(id: 10)
        /// Laminar mainnet, standard account (*25519).
        public static let laminar = Self(id: 11)
        /// Polymath network, standard account (*25519).
        public static let polymath = Self(id: 12)
        /// Any SubstraTEE off-chain network private account (*25519).
        public static let substraTee = Self(id: 13)
        /// Any Totem Live Accounting network standard account (*25519).
        public static let totem = Self(id: 14)
        /// Synesthesia mainnet, standard account (*25519).
        public static let synesthesia = Self(id: 15)
        /// Kulupu mainnet, standard account (*25519).
        public static let kulupu = Self(id: 16)
        /// Dark mainnet, standard account (*25519).
        public static let dark = Self(id: 17)
        /// Darwinia Chain mainnet, standard account (*25519).
        public static let darwinia = Self(id: 18)
        /// GeekCash mainnet, standard account (*25519).
        public static let geek = Self(id: 19)
        /// Stafi mainnet, standard account (*25519).
        public static let stafi = Self(id: 20)
        /// Dock testnet, standard account (*25519).
        public static let dockTest = Self(id: 21)
        /// Dock mainnet, standard account (*25519).
        public static let dockMain = Self(id: 22)
        /// ShiftNrg mainnet, standard account (*25519).
        public static let shiftNrg = Self(id: 23)
        /// ZERO mainnet, standard account (*25519).
        public static let zero = Self(id: 24)
        /// ZERO testnet, standard account (*25519).
        public static let alphaville = Self(id: 25)
        /// Jupiter testnet, standard account (*25519).
        public static let jupiter = Self(id: 26)
        /// Patract mainnet, standard account (*25519).
        public static let patract = Self(id: 27)
        /// Subsocial network, standard account (*25519).
        public static let subsocial = Self(id: 28)
        /// Dhiway CORD network, standard account (*25519).
        public static let dhiway = Self(id: 29)
        /// Phala Network, standard account (*25519).
        public static let phala = Self(id: 30)
        /// Litentry Network, standard account (*25519).
        public static let litentry = Self(id: 31)
        /// Any Robonomics network standard account (*25519).
        public static let robonomics = Self(id: 32)
        /// DataHighway mainnet, standard account (*25519).
        public static let dataHighway = Self(id: 33)
        /// Ares Protocol, standard account (*25519).
        public static let ares = Self(id: 34)
        /// Valiu Liquidity Network mainnet, standard account (*25519).
        public static let valiu = Self(id: 35)
        /// Centrifuge Chain mainnet, standard account (*25519).
        public static let centrifuge = Self(id: 36)
        /// Nodle Chain mainnet, standard account (*25519).
        public static let nodle = Self(id: 37)
        /// KILT Chain mainnet, standard account (*25519).
        public static let kilt = Self(id: 38)
        /// Polimec Chain mainnet, standard account (*25519).
        public static let polimec = Self(id: 41)
        /// Any Substrate network, standard account (*25519).
        public static let substrate = Self(id: 42)
        /// Bare ECDSA SECP256k1 key.
        public static let bareSecp256k1 = Self(id: 43)
        /// ChainX mainnet, standard account (*25519).
        public static let chainX = Self(id: 44)
        /// UniArts Chain mainnet, standard account (*25519).
        public static let uniarts = Self(id: 45)
        /// Reserved for future use (46).
        public static let reserved46 = Self(id: 46)
        /// Reserved for future use (47).
        public static let reserved47 = Self(id: 47)
        /// Neatcoin Mainnet (*25519)
        public static let neatcoin = Self(id: 48)
        /// HydraDX (*25519)
        public static let hydradx = Self(id: 63)
        /// Aventus Chain mainnet, standard account (*25519).
        public static let aventus = Self(id: 65)
        /// Crust Network, standard account (*25519).
        public static let crust = Self(id: 66)
        /// SORA Network, standard account (*25519).
        public static let sora = Self(id: 69)
        /// Social Network, standard account (*25519).
        public static let socialNetwork = Self(id: 252)
        /// Note: 49 and above are reserved.
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let uint = try container.decode(UInt16.self)
            guard let format = Self(rawValue: uint) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Bad SS58.AddressFormat value \(uint)"
                )
            }
            self.init(id: format.rawValue)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
    }
    
    public struct AddressCodec {
        public func decode(string: String) throws -> (Data, AddressFormat) {
            let data = try Base58.decode(string)
            guard data.count >= 2 else { throw Error.badLength }
            let prefixLen: Int, ident: UInt16
            switch data[0] {
            case 0..<64:
                prefixLen = 1
                ident = UInt16(data[0])
            case 64..<128:
                // weird bit manipulation owing to the combination of LE encoding and missing two bits
                // from the left.
                // d[0] d[1] are: 01aaaaaa bbcccccc
                // they make the LE-encoded 16-bit value: aaaaaabb 00cccccc
                // so the lower byte is formed of aaaaaabb and the higher byte is 00cccccc
                let lower = (data[0] << 2) | (data[1] >> 6)
                let upper = data[1] & 0b00111111
                ident = UInt16(lower) | (UInt16(upper) << 8)
                prefixLen = 2
            default: throw Error.unknownVersion
            }
            
            let cLength = try checksumLength(for: data.count, prefix: prefixLen)
            guard let format = AddressFormat(rawValue: ident) else {
                throw Error.formatNotAllowed
            }
            let body = Data(data.prefix(data.count - cLength))
            let dhash = hash(data: body)
            let checksum = Array(dhash.prefix(cLength))
            guard checksum == data.suffix(cLength) else {
                throw Error.invalidChecksum
            }
            return (body.suffix(from: prefixLen), format)
        }
        
        public func encode(data: Data, format: AddressFormat) -> String {
            // We mask out the upper two bits of the ident - SS58 Prefix currently only supports 14-bits
            let ident = format.id & 0b00111111_11111111
            var result = Array<UInt8>()
            switch ident {
            case 0..<64: result.append(UInt8(ident))
            case 64..<16_384:
                // upper six bits of the lower byte(!)
                result.append((UInt8(ident & 0b00000000_11111100) >> 2) | 0b01000000)
                // lower two bits of the lower byte in the high pos,
                // lower bits of the upper byte in the low pos
                result.append(UInt8(ident >> 8) | UInt8(ident & 0b00000000_00000011) << 6)
            default:
                fatalError("masked out the upper two bits; qed")
            }
            let cLength = data.count > 1 ? Self.defaultEncodeChecksumLength : 1
            result.append(contentsOf: data)
            let rhash = hash(data: Data(result))
            result.append(contentsOf: rhash.prefix(cLength))
            return Base58.encode(result)
        }
        
        public func hash(data: Data) -> Data {
            HBlake2b512.instance.hash(data: Self.prefix + data)
        }
        
        public func checksumLength(for dataLength: Int, prefix: Int) throws -> Int {
            let bodyLength = dataLength - prefix
            if prefix == 1 {
                switch bodyLength {
                case 2: return 1
                case 3, 4: return bodyLength - 2
                case 5..<9: return bodyLength - 4
                case 9..<17: return bodyLength - 8
                case 34, 35: return 2
                default: throw Error.badLength
                }
            } else if prefix == 2 {
                switch bodyLength {
                case 34, 35: return 2
                default: throw Error.badLength
                }
            } else {
                throw Error.badLength
            }
        }
        
        public static let prefix = Data("SS58PRE".utf8)
        public static let instance = AddressCodec()
        public static let defaultEncodeChecksumLength = 2
    }
    
    public enum Error: Swift.Error {
        case badLength
        case unknownVersion
        case formatNotAllowed
        case invalidChecksum
    }
}
