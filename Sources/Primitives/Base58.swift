//
//  Base58.swift
//  
//
//  Created by Yehor Popovych on 04.05.2021.
//
//  Based on https://github.com/Alja7dali/swift-base58 project.
//

import Foundation

private let Base58Alphabet = [UInt8]("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz".utf8)

private let Base58DecodingTable: [UInt8: UInt8] = {
    let pairs = Base58Alphabet.enumerated().map { index, char in
        (char, UInt8(index))
    }
    return Dictionary(pairs) { (l, _) in l }
}()

private let encode: (UInt8) -> UInt8 = {
    $0 < Base58Alphabet.count ? Base58Alphabet[Int($0)] : .max
}

private let decode: (UInt8) -> UInt8? = {
  Base58DecodingTable[$0]
}

public func base58_encode(
  _ bytes: Array<UInt8>,
  alphabet mapper: Optional<(UInt8) -> UInt8> = .none
) -> String {
  let mapper = mapper ?? encode

  var zerosCount = 0

  while bytes[zerosCount] == 0 {
    zerosCount += 1
  }

  let bytesCount = bytes.count - zerosCount
  let b58Count = ((bytesCount * 138) / 100) + 1
  var b58 = [UInt8](repeating: 0, count: b58Count)
  var count = 0

  var x = zerosCount
  while x < bytesCount {
    var carry = Int(bytes[x]), i = 0, j = b58Count - 1
    while j > -1 {
      if carry != 0 || i < count {
        carry += 256 * Int(b58[j])
        b58[j] = UInt8(carry % 58)
        carry /= 58
        i += 1
      }
      j -= 1
    }
    count = i
    x += 1
  }

  // skip leading zeros
  var leadingZeros = 0
  while b58[leadingZeros] == 0 {
    leadingZeros += 1
  }

  let result = Data(repeating: Base58Alphabet[0], count: zerosCount)
       + Data(b58[leadingZeros...]).map(mapper)
  return String(data: result, encoding: .utf8)!
}


public enum Base58DecodingError: Error {
  case invalidByte(UInt8)
}

public func base58_decode(
  _ string: String,
  alphabet mapper: Optional<(UInt8) -> UInt8?> = .none
) throws -> Array<UInt8> {
  let mapper = mapper ?? decode
  let bytes = Array(string.utf8)

  var onesCount = 0

  while bytes[onesCount] == Base58Alphabet[0] {
    onesCount += 1
  }

  let bytesCount = bytes.count - onesCount
  let b58Count = ((bytesCount * 733) / 1000) + 1 - onesCount
  var b58 = [UInt8](repeating: 0, count: b58Count)
  var count = 0

  var x = onesCount
  while x < bytesCount {
    guard let b58Index = mapper(bytes[x]) else {
      throw Base58DecodingError.invalidByte(bytes[x])
    }
    var carry = Int(b58Index), i = 0, j = b58Count - 1
    while j > -1 {
      if carry != 0 || i < count {
        carry += 58 * Int(b58[j])
        b58[j] = UInt8(carry % 256)
        carry /= 256
        i += 1
      }
      j -= 1
    }
    count = i
    x += 1
  }

  // skip leading zeros
  var leadingZeros = 0
  while b58[leadingZeros] == 0 {
    leadingZeros += 1
  }

  return [UInt8](repeating: 0, count: onesCount)
       + [UInt8](b58[leadingZeros...])
}
