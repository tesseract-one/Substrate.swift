import XCTest

import PolkadotTests
import PrimitivesTests
import RPCTests

var tests = [XCTestCaseEntry]()
tests += PolkadotTests.__allTests()
tests += PrimitivesTests.__allTests()
tests += RPCTests.__allTests()

XCTMain(tests)
