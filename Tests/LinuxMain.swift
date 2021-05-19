import XCTest

import KeychainTests
import PolkadotTests
import PrimitivesTests
import RPCTests
import SubstrateTests

var tests = [XCTestCaseEntry]()
tests += KeychainTests.__allTests()
tests += PolkadotTests.__allTests()
tests += PrimitivesTests.__allTests()
tests += RPCTests.__allTests()
tests += SubstrateTests.__allTests()

XCTMain(tests)
