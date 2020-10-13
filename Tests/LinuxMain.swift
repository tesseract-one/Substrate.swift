import XCTest

import PolkadotTests
import PrimitivesTests

var tests = [XCTestCaseEntry]()
tests += PolkadotTests.__allTests()
tests += PrimitivesTests.__allTests()

XCTMain(tests)
